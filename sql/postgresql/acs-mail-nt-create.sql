-- acs-mail-nt-create.sql
--
-- replicate basic functionality of acs-notifications in acs-mail
-- This will make acs-notifications obsolete and aggregate
--   all mail and alert functions into acs-mail
--
-- @author Vinod Kurup (vkurup@massmed.org)
--


-- /** acs_mail_nt__post_request
--     * Post a notification request
--     * A new CR item will be created and inserted into an acs_mail_body
--     * This acs_mail_body will then be queued.
--     * When tcl proc 'acs_mail_process_queue' gets run (every 15 min),
--       this message will be sent via ns_sendmail
--     * original nt.post_request by Stanislav Freidin 
--
--    @author Vinod Kurup
--    @param party_from    The id of the sending party
--    @param party_to      The id of the sending party
--    @param expand_group  if t, send email to individual members of group
--						   if f, send email to group's email addr only
--    @param subject       A one-line subject for the message
--    @param message       The body of the message
--    @param max_retries   part of old nt API - no longer supported
--    @return The id of the new request
-- */

create or replace function acs_mail_nt__post_request(integer,integer,boolean,varchar,text,integer)
returns integer as '
declare
	p_party_from		alias for $1;
	p_party_to		alias for $2;
	p_expand_group		alias for $3;	-- default ''f''
	p_subject		alias for $4;
	p_message		alias for $5;
	p_max_retries		alias for $6;	-- default 0
	v_header_from		acs_mail_bodies.header_from%TYPE;
	v_header_to		acs_mail_bodies.header_to%TYPE;
	v_body_id		acs_mail_bodies.body_id%TYPE;
	v_item_id		cr_items.item_id%TYPE;
	v_revision_id		cr_revisions.revision_id%TYPE;
	v_message_id		acs_mail_queue_messages.message_id%TYPE;
	v_header_to_rec		record;
	v_creation_user		acs_objects.creation_user%TYPE;
begin
	if p_max_retries <> 0 then
	   raise EXCEPTION '' -20000: max_retries parameter not implemented.'';
	end if;

	-- get the sender email address
	select max(email) 
	into v_header_from 
	from parties 
	where party_id = p_party_from;

	-- if sender address is null, then use site default OutgoingSender
	if v_header_from is null then
	   	select apm__get_value(package_id, ''OutgoingSender'') into v_header_from
		from apm_packages where package_key=''acs-kernel'';
	end if;

	-- make sure that this party is in users table. If not, let creation_user
	-- be null to prevent integrity constraint violations on acs_objects
	select max(user_id) 
	into v_creation_user 
	from users 
	where user_id = p_party_from;

	-- get the recipient email address
	select max(email) 
	into v_header_to 
	from parties 
	where party_id = p_party_to;

	-- do not let any of these addresses be null
	if v_header_from is null or v_header_to is null then
	   raise EXCEPTION '' -20000: acs_mail_nt: cannot sent email to blank address or from blank address.'';
	end if;

	-- create a mail body with empty content
	select acs_mail_body__new (
		null,			-- p_body_id
		null,			-- p_body_reply_to
		p_party_from,		-- p_body_from
		now(),			-- p_body_date
		null,			-- p_header_message_id
		null,			-- p_header_reply_to
		p_subject,		-- p_header_subject
		null,			-- p_header_from
		null,			-- p_header_to
		null,			-- p_content_item_id
		''acs_mail_body'',	-- p_object_type
		now() ::date,		-- p_creation_date
		v_creation_user,	-- p_creation_user
		null,			-- p_creation_ip
		null			-- p_context_id
	) into v_body_id;

	-- create a CR item to stick p_message into
	select content_item__new(
	        ''acs-mail message'' || v_body_id,	-- new__name
	        null,					-- new__parent_id
	        p_subject,				-- new__title
	        null,					-- new__description
	        p_message				-- new__text
	) into v_item_id;

	-- content_item__new makes a CR revision. We need to get that revision
	-- and make it live
	select content_item__get_latest_revision (v_item_id) 
	into v_revision_id;

	perform content_item__set_live_revision ( v_revision_id );

	-- set the content of the message
	perform acs_mail_body__set_content_object( v_body_id, v_item_id );

	-- queue the message
	select acs_mail_queue_message__new (
		null,				-- p_mail_link_id
		v_body_id,			-- p_body_id
		null,				-- p_context_id
		now(),				-- p_creation_date
		v_creation_user,		-- p_creation_user
		null,				-- p_creation_ip
		''acs_mail_link''		-- p_object_type
	) into v_message_id;

	-- now put the message into the outgoing queue
	-- i know this seems redundant, but that''s the way it was built
	-- the idea is that you put a generic message into the main queue
	-- without from or to address, and then insert a copy of the message
	-- into the outgoing_queue with the specific from and to address
	if p_expand_group = ''f'' then
		insert into acs_mail_queue_outgoing
		( message_id, envelope_from, envelope_to )
		values
		( v_message_id, v_header_from, v_header_to );

	else
		-- expand the group
		-- FIXME: need to check if this is a group and if there are members
		--        if not, do we need to notify sender?
		for v_header_to_rec in 
			select email 
			from parties p 
			where party_id in (
				select member_id 
				from group_approved_member_map 
				where group_id = p_party_to
			) 
		loop
			insert into acs_mail_queue_outgoing
			( message_id, envelope_from, envelope_to )
			values
			( v_message_id, v_header_from, v_header_to_rec.email );
		end loop;

	end if;
	return v_message_id;
end;' language 'plpgsql';


-- /** acs_mail_nt__post_request
--   * Overloaded function that
--   * only uses the basic params
--
--    @author: Vinod Kurup
--    @param party_from    The id of the sending party
--    @param party_to      The id of the sending party
--    @param subject       A one-line subject for the message
--    @param message       The body of the message
--    @return The id of the new request
--
create or replace function acs_mail_nt__post_request(integer,integer,varchar,text)
returns integer as '
declare
	p_party_from		alias for $1;
	p_party_to			alias for $2;
	p_subject			alias for $3;
	p_message			alias for $4;
begin
	return acs_mail_nt__post_request(
		p_party_from,		-- p_party_from
		p_party_to,			-- p_party_to
		''f'',				-- p_expand_group
		p_subject,			-- p_subject
		p_message,			-- p_message
		0					-- p_max_retries
	);
end;' language 'plpgsql';


-- /** acs_mail_nt__cancel_request
--    * Cancel a notification request
--    * Original author: Stanislav Freidin
--
--    @author Vinod Kurup
--    @param request_id    Id of the request to cancel
-- */

create or replace function acs_mail_nt__cancel_request (integer)
returns integer as '
declare
	p_message_id		alias for $1;
begin
	perform acs_mail_queue_message__delete ( p_message_id );
	return 0;
end;' language 'plpgsql';


-- /** acs_mail_nt__expand_requests
--     * This was part of the nt package, but is no longer relevant
--     * There is no replacement
--
--		@author Vinod Kurup
-- */

create or replace function acs_mail_nt__expand_requests ()
returns integer as '
begin
	raise EXCEPTION ''-20000: Procedure no longer supported.'';
	return 0;
end;' language 'plpgsql';


-- /** acs_mail_nt__update_requests
--     * This was part of the nt package, but is no longer relevant
--     * There is no replacement
--
--		@author Vinod Kurup
-- */

create or replace function acs_mail_nt__update_requests ()
returns integer as '
begin
	raise EXCEPTION ''-20000: Procedure no longer supported.'';
	return 0;
end;' language 'plpgsql';


-- /** acs_mail_nt__process_queue
--     * This was part of the nt package, but is no longer relevant
--     * Instead use the tcl proc: acs_mail_process_queue
--
--		@author Vinod Kurup
-- */

create or replace function acs_mail_nt__process_queue (varchar,integer)
returns integer as '
declare
	p_host		alias for $1;
	p_port		alias for $2;	-- default 25
begin
	raise EXCEPTION ''-20000: Procedure no longer supported - see packages/acs-mail/sql/postgresql/acs-mail-nt-create.sql.'';

	return 0;
end;' language 'plpgsql';


-- /** acs_mail_nt__schedule_process
--     * This was part of the nt package, but is no longer relevant
--     * Instead, use ad_schedule_proc to schedule 
--       the tcl proc acs_mail_process_queue
--     * Note: this is already done in a default install
--       See packages/acs-mail/tcl/acs-mail-init.tcl
--
--		@author Vinod Kurup
-- */

create or replace function acs_mail_nt__schedule_process (numeric,varchar,integer)
returns integer as '
declare
	p_interval	alias for $1;
	p_host		alias for $2;
	p_port		alias for $3;	-- default 25
begin
	raise EXCEPTION ''-20000: Procedure no longer supported - see packages/acs-mail/sql/postgresql/acs-mail-nt-create.sql. '';
	return 0;
end;' language 'plpgsql';

