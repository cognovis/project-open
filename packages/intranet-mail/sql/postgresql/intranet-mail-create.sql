-- 
-- packages/intranet-mail/sql/postgresql/intranet-mail-create.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2011-04-21
-- @cvs-id $Id$
--

CREATE TABLE acs_mail_lite_complex_queue (
   id                          integer
                               constraint acs_mail_lite_complex_queue_pk
                               primary key,
   creation_date               text,
   locking_server              text,
   to_party_ids                text,
   cc_party_ids                text,
   bcc_party_ids               text,
   to_group_ids                text,
   cc_group_ids                text,
   bcc_group_ids               text,
   to_addr                     text,
   cc_addr                     text,
   bcc_addr                    text,
   from_addr                   text,
   reply_to                    text,
   subject                     text,
   body                        text,
   package_id                  integer,
   files                       text,
   file_ids                    text,
   folder_ids                  text,
   mime_type                   text,
   object_id                   integer,
   single_email_p              boolean,
   no_callback_p               boolean,
   extraheaders                text,
   alternative_part_p          boolean,
   use_sender_p                boolean
);

--  ======================================================
-- Tracking Table acs_object_log 			--
--  ======================================================

create table acs_mail_log (
	
	log_id			integer
	                        constraint acs_mail_log_log_id_pk
				primary key,
	message_id		varchar(300),
	-- object_id of the object that triggered the sending of the email
	object_id		integer
				constraint acs_mail_log_owner_id_fk
				references acs_objects(object_id),
	sender_id		integer
				constraint acs_mail_log_sender_id_fk
				references parties(party_id),
	package_id		integer,
	subject			varchar(1024),
	body			text,
	-- List of CC/BCC E-Mail addresses, seperated by "," as passed in from acs-mail-lite::send prozedures
	-- Only used for those emails that do not have a party_id in openacs.
	cc			varchar(4000),
	bcc			varchar(4000),
	sent_date		timestamp,
        to_addr                 varchar(4000),
        from_addr               varchar(400));


create index acs_mail_log_object_idx on acs_mail_log(object_id);
create index acs_mail_log_sender_idx on acs_mail_log(sender_id);
create index acs_mail_log_object_message_idx on acs_mail_log(object_id,message_id);

create table acs_mail_log_recipient_map (
	recipient_id		integer	constraint 
	 			acs_mail_log_recipient_id_fk
				references parties(party_id),
	log_id			integer	
 				constraint acs_mail_log_log_id_fk
				references acs_mail_log(log_id),
	type 			varchar(30)
);

create index acs_mail_log_recipient_map_log_idx on acs_mail_log_recipient_map(log_id);
create index acs_mail_log_recipient_map_recipient_idx on acs_mail_log_recipient_map(recipient_id);
create index acs_mail_log_um_log_rec_idx on acs_mail_log_recipient_map(log_id,recipient_id,type);

-- file_mapping_table
create table acs_mail_log_attachment_map (
	log_id 			integer
				constraint acs_mail_log_log_id2_fk
				references acs_mail_log(log_id),
	file_id			integer
				constraint acs_mail_log_file_id_fk
				references cr_revisions(revision_id)
);

create index acs_mail_log_att_map_file_idx on acs_mail_log_attachment_map(file_id);	
create index acs_mail_log_att_map_log_idx on acs_mail_log_attachment_map(log_id);	


-- create the content type
select acs_object_type__create_type (
   'mail_log',              -- content_type
   '#intranet-mail.ACS_Mail_Log_Entry#',             -- pretty_name 
   '#intranet-mail.ACS_Mail_Log_Entries#',           -- pretty_plural
   'acs_object',                  -- supertype
   'acs_mail_log',            -- table_name (should this be pm_task?)
   'log_id',                   -- id_column 
   'mail_tracking',              -- package_name
   'f',                           -- abstract_p
   NULL,                          -- type_extension_table
   NULL                           -- name_method
);

create or replace function acs_mail_log__new (integer,varchar, integer, integer, varchar, varchar,integer,varchar,integer,integer,varchar,varchar,varchar)
returns integer as '
declare	
	p_log_id alias for $1;
	p_message_id alias for $2;
	p_sender_id alias for $3;
	p_package_id alias for $4;
	p_subject alias for $5;
	p_body alias for $6;
	p_creation_user alias for $7;
        p_creation_ip alias for $8;
        p_context_id alias for $9;
	p_object_id alias for $10;
	p_cc alias for $11;
	p_bcc alias for $12;
	p_to_addr alias for $13;
	v_log_id acs_mail_log.log_id%TYPE;
begin
	v_log_id := acs_object__new (
		p_log_id,         -- object_id
		''mail_log'' -- object_type
	);

	insert into acs_mail_log
		(log_id, message_id, sender_id, package_id, subject, body, sent_date, object_id, cc, bcc, to_addr)
	values
		(v_log_id, p_message_id, p_sender_id, p_package_id, p_subject, p_body, now(), p_object_id, p_cc, p_bcc, p_to_addr);

	return v_log_id;

end;' language 'plpgsql';


create function acs_mail_log__delete (integer)
returns integer as'
declare
	p_message_id		alias for $1;
begin

		delete from acs_mail_log where message_id = p_message_id;

		raise NOTICE ''Deleting Acs Mail Log Entry...'';

		PERFORM acs_object_delete(p_message_id);

		return 0;

end;' language 'plpgsql';


--  ======================================================
-- Tracking requests table acs_mail_tracking_request	--
--  ======================================================

create table acs_mail_tracking_request (
    request_id                      integer
                                    constraint acs_mail_request_id_pk
                                    primary key,
    user_id                         integer
                                    constraint acs_mail_request_user_id_fk
                                    references users (user_id),
                                    -- on delete cascade,
    -- The package instance this request pertains to
    object_id                       integer
                                    constraint acs_mail_request_object_id_fk
                                    references acs_objects (object_id)
                                    -- on delete cascade
);


create or replace function acs_mail_tracking_request__new (integer,integer,integer)
returns integer as '

DECLARE
        p_request_id			alias for $1;      
        p_object_id			alias for $2;
        p_user_id			alias for $3;
	v_request_id			integer;

BEGIN

	select t_acs_object_id_seq.NEXTVAL into v_request_id;
	
      insert into acs_mail_tracking_request
      	(request_id, object_id, user_id)
      values
      	(p_request_id, p_object_id, p_user_id);

      return v_request_id;

END;
' language 'plpgsql';


create or replace function acs_mail_tracking_request__delete(integer)
returns integer as '
declare
    p_request_id                    alias for $1;
begin
    delete from acs_mail_tracking_request where request_id = p_request_id;
    return 0;
end;
' language 'plpgsql';


create or replace function acs_mail_tracking_request__delete_all(integer)
returns integer as '
declare
    v_request                       RECORD;

begin
    for v_request in select request_id from acs_mail_tracking_request
    loop
        perform acs_mail_tracking_request__delete(v_request.request_id);
    end loop;

    return 0;
end;
' language 'plpgsql';



-- Component for projects
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet Mail Project Component',        -- plugin_name
        'intranet-mail',                  -- package_name
        'right',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        12,                             -- sort_order
        'im_mail_project_component -project_id $project_id -return_url $return_url'
);

-- Component for tasks
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet Mail Task Component',        -- plugin_name
        'intranet-mail',                  -- package_name
        'right',                        -- location
        '/intranet-cognovis/tasks/view',      -- page_url
        null,                           -- view_name
        12,                             -- sort_order
        'im_mail_project_component -project_id $task_id -return_url $return_url'
);

-- Component for tickets
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet Mail Ticket Component',        -- plugin_name
        'intranet-mail',                  -- package_name
        'right',                        -- location
        '/intranet-cognovis/tickets/view',      -- page_url
        null,                           -- view_name
        12,                             -- sort_order
        'im_mail_project_component -project_id $ticket_id -return_url $return_url'
);




CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	-- Intranet Mail Project Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Intranet Mail Project Component'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');



	-- Intranet Mail Task Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Intranet Mail Task Component'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Intranet Mail Ticket Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Intranet Mail Ticket Component'' AND page_url = ''/intranet-cognovis/tickets/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');
	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();
