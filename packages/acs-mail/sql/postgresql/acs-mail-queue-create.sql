--
-- packages/acs-mail/sql/acs-mail-queue-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

select acs_object_type__create_type (
    'acs_mail_queue_message',
    'Queued Message',
    'Queued Messages',
    'acs_mail_link',
    'acs_mail_queue_messages',
    'message_id',
    null,
    'f',
    null,
    'acs_object.default_name'
);

create table acs_mail_queue_messages (
    message_id		integer
					constraint acs_mail_queue_ml_id_pk 
					primary key
					constraint acs_mail_queue_ml_id_fk 
					references acs_mail_links on delete cascade
);

create table acs_mail_queue_incoming (
    message_id		integer
					constraint acs_mail_queue_in_mlid_pk 
					primary key
					constraint acs_mail_queue_in_mlid_fk
					references acs_mail_queue_messages on delete cascade,
    envelope_from	text,
    envelope_to		text
);

create table acs_mail_queue_outgoing (
    message_id		integer
					constraint acs_mail_queue_out_mlid_fk
					references acs_mail_queue_messages on delete cascade,
    envelope_from	text,
    envelope_to		text,
	constraint acs_mail_queue_out_pk
	primary key (message_id, envelope_to)
);

-- API -----------------------------------------------------------------
--create or replace package body acs_mail_queue_message__
create function acs_mail_queue_message__new (integer,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
	p_mail_link_id			alias for $1;    -- default null
	p_body_id				alias for $2;
	p_context_id			alias for $3;    -- default null
	p_creation_date			alias for $4;    -- default now()
	p_creation_user			alias for $5;    -- default null
	p_creation_ip			alias for $6;    -- default null
	p_object_type			alias for $7;    -- default acs_mail_link
    v_mail_link_id			acs_mail_links.mail_link_id%TYPE;
begin
    v_mail_link_id := acs_mail_link__new (
		p_mail_link_id,			-- mail_link_id 
		p_body_id,				-- body_id 
		p_context_id,			-- context_id 
		p_creation_date,		-- creation_date 
		p_creation_user,		-- creation_user 
		p_creation_ip,			-- creation_ip 
		p_object_type			-- object_type 
    );

    insert into acs_mail_queue_messages 
	 ( message_id )
    values 
	 ( v_mail_link_id );

    return v_mail_link_id;
end;' language 'plpgsql';

create function acs_mail_queue_message__delete (integer)
returns integer as '
declare
	p_message_id		alias for $1;
begin
	perform acs_mail_link__delete( p_message_id );

    return 1;
end;' language 'plpgsql';
-- end acs_mail_queue_message;


-- Needs:
--   Incoming:
--     A way to say "okay, I've accepted this one, go ahead and delete"
--   Outgoing:
--     A way to say "send this message to this person from this person"
--     A way to say "send this message to these people from this person"
