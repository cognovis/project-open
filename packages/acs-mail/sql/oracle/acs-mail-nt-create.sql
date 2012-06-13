-- acs-mail-nt-create.sql
--
-- replicate basic functionality of acs-notifications in acs-mail
-- This will make acs-notifications obsolete and aggregate
--   all mail and alert functions into acs-mail
--
-- ported from PG to oracle
--
-- @author Vinod Kurup (vkurup@massmed.org)
-- @creation-date 2001-08-04
-- @cvs-id $Id$

create or replace package acs_mail_nt
as

-- /** acs_mail_nt.post_request
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
--    @param expand_group  part of old nt API - no longer supported
--    @param subject       A one-line subject for the message
--    @param message       The body of the message
--    @param max_retries   part of old nt API - no longer supported
--    @return The id of the new request
-- */

 function post_request (
	party_from		in parties.party_id%TYPE,
	party_to		in parties.party_id%TYPE,
	expand_group	in char				default 'f',
	subject			in acs_mail_bodies.header_subject%TYPE,
	message			in varchar2,
	max_retries		in integer			default 0
 ) return acs_mail_queue_messages.message_id%TYPE;

-- /** acs_mail_nt.cancel_request
--    * Cancel a notification request
--    * Original author: Stanislav Freidin
--
--    @author Vinod Kurup
--    @param request_id    Id of the request to cancel
-- */

 procedure cancel_request (
	message_id		in acs_mail_queue_messages.message_id%TYPE
 );

-- /** acs_mail_nt.expand_requests
--     * This was part of the nt package, but is no longer relevant
--     * There is no replacement
--
--		@author Vinod Kurup
-- */

 procedure expand_requests;

-- /** acs_mail_nt.update_requests
--     * This was part of the nt package, but is no longer relevant
--     * There is no replacement
--
--		@author Vinod Kurup
-- */

 procedure update_requests;

-- /** acs_mail_nt.process_queue
--     * This was part of the nt package, but is no longer relevant
--     * Instead use the tcl proc: acs_mail_process_queue
--
--		@author Vinod Kurup
-- */

 procedure process_queue (
	host			in varchar2,
	port			in integer			default 25
 );

-- /** acs_mail_nt.schedule_process
--     * This was part of the nt package, but is no longer relevant
--	   * Instead, use ad_schedule_proc to schedule 
--       the tcl proc acs_mail_process_queue
--     * Note: this is already done in a default install
--       See packages/acs-mail/tcl/acs-mail-init.tcl
--
--		@author Vinod Kurup
-- */

 procedure schedule_process (
	interval		in number,
	host			in varchar2,
	port			in integer			default 25
 );

end acs_mail_nt;
/
show errors


create or replace package body acs_mail_nt
as

 function post_request (
	party_from		in parties.party_id%TYPE,
	party_to		in parties.party_id%TYPE,
	expand_group	in char				default 'f',
	subject			in acs_mail_bodies.header_subject%TYPE,
	message			in varchar2,
	max_retries		in integer			default 0
 ) return acs_mail_queue_messages.message_id%TYPE
 is
	cursor c_expanded_cur is 
		   select email from parties p 
			where p.party_id in (select member_id from group_approved_member_map 
								where group_id = party_to);
	c_request_row	c_expanded_cur%ROWTYPE;
	v_header_from	acs_mail_bodies.header_from%TYPE;
	v_header_to		acs_mail_bodies.header_to%TYPE;
	v_body_id		acs_mail_bodies.body_id%TYPE;
	v_item_id		cr_items.item_id%TYPE;
	v_revision_id	cr_revisions.revision_id%TYPE;
	v_message_id	acs_mail_queue_messages.message_id%TYPE;
	v_creation_user	acs_objects.creation_user%TYPE;
 begin
	if max_retries <> 0 then
	   raise_application_error(-20000,
			'max_retries parameter not implemented.'
		);
	end if;

	-- get the sender email address
	select max(email) into v_header_from from parties where party_id = party_from;

	-- if sender address is null, then use site default OutgoingSender
	if v_header_from is null then
	   	select apm.get_value(package_id, 'OutgoingSender') into v_header_from
		from apm_packages where package_key='acs-kernel';
	end if;

	-- make sure that this party is in users table. If not, let creation_user
	-- be null to prevent integrity constraint violations on acs_objects
	select max(user_id) into v_creation_user 
      from users where user_id = party_from;

	-- get the recipient email address
	select max(email) into v_header_to from parties where party_id = party_to;

	-- do not let any of these addresses be null
	if v_header_from is null or v_header_to is null then
	   raise_application_error(-20000,
			'acs_mail_nt: cannot sent email to blank address or from blank address.'
	   );
	end if;

	-- create a mail body with empty content

	v_body_id := acs_mail_body.new (
		body_from => party_from,
		body_date => sysdate,
		header_subject => subject,
		creation_user => v_creation_user
	);

	-- create a CR item to stick message into
	-- for oracle, we need to stick it in a blob

	v_item_id := content_item.new (
		name  => 'acs-mail message' || v_body_id,	
        title => subject,
        text  => message
	);

	-- content_item__new makes a CR revision. We need to get that revision
	-- and make it live

	v_revision_id := content_item.get_latest_revision (v_item_id);
	content_item.set_live_revision ( v_revision_id );

	-- set the content of the message
	acs_mail_body.set_content_object( v_body_id, v_item_id );

	-- queue the message
	v_message_id := acs_mail_queue_message.new (
		body_id       => v_body_id,
		creation_user => v_creation_user
	);

	-- now put the message into the outgoing queue
	-- i know this seems redundant, but that's the way it was built.
	-- The idea is that you put a generic message into the main queue
	-- without from or to address, and then insert a copy of the message
	-- into the outgoing_queue with the specific from and to address

    if expand_group = 'f' then
	   insert into acs_mail_queue_outgoing
	   ( message_id, envelope_from, envelope_to )
	   values
	   ( v_message_id, v_header_from, v_header_to );
	else
		-- expand the group
		-- FIXME: need to check if this is a group and if there are members
		--        if not, do we need to notify sender?

		for c_request_row in c_expanded_cur loop
			insert into acs_mail_queue_outgoing
			( message_id, envelope_from, envelope_to ) 
			values 
			( v_message_id, v_header_from, c_request_row.email );
		end loop;
	end if;

	return v_message_id;
 end post_request;

 procedure cancel_request (
	message_id		in acs_mail_queue_messages.message_id%TYPE
 ) 
 is
 begin
	acs_mail_queue_message.del ( message_id );
 end cancel_request;

 procedure expand_requests
 is
 begin
   raise_application_error(-20000,
		'Procedure expand_requests no longer supported.'
      );
 end expand_requests;

 procedure update_requests 
 is
 begin
	raise_application_error(-20000, 
		'Procedure no longer supported.'
	);
 end update_requests;

 procedure schedule_process (
	interval		in number,
	host			in varchar2,
	port			in integer			default 25
 ) 
 is
 begin
	raise_application_error(-20000,
		'Procedure no longer supported - see packages/acs-mail/sql/oracle/acs-mail-nt-create.sql.'
	);
 end schedule_process;

 procedure process_queue (
	host			in varchar2,
	port			in integer			default 25
 ) 
 is
 begin
	raise_application_error(-20000,
		'Procedure no longer supported - see packages/acs-mail/sql/oracle/acs-mail-nt-create.sql.'
	);
 end process_queue;

end acs_mail_nt;
/
show errors

