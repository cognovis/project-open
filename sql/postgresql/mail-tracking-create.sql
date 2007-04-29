--  ================================================================================
-- Postgres SQL Script File
-- 
-- 
-- @Location: mail-tracking\sql\postgresql\acs_mail_log-create.sql
-- 
-- @author: Nima Mazloumi
-- @creation-date: Mon May 30 17:55:50 CEST 2005
-- @cvs-id $Id$
--  ================================================================================
-- 
-- 

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
				references cr_items(item_id)
);

create index acs_mail_log_att_map_file_idx on acs_mail_log_attachment_map(file_id);	
create index acs_mail_log_att_map_log_idx on acs_mail_log_attachment_map(log_id);	


-- create the content type
select acs_object_type__create_type (
   'mail_log',              -- content_type
   '#mail-tracking.ACS_Mail_Log_Entry#',             -- pretty_name 
   '#mail-tracking.ACS_Mail_Log_Entries#',           -- pretty_plural
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


--  ======================================================
-- Tracking Trigger acs_mail_log_tr			--
--  ======================================================

-- CREATE OR REPLACE FUNCTION public.acs_mail_log_tr()
--  RETURNS trigger AS
--'
--declare
--     v_recepient_id         	integer;  
--     v_sender_id       		integer default 0;
--     v_track_all_p		bool default 0;
--    v_object_id		integer;
--    begin
--
--	if old.package_id is null then 
--            raise notice \'Tracking: No way to track. Package Id was %. You need to check why.\', old.package_id;
--            return old;
--       end if;
--       
--       v_recepient_id := substring (old.to_addr from \'user_id ([0-9]+)\');
--	select into v_sender_id party_id from parties where email = old.from_addr;
--
--   if v_recepient_id is null then
--        raise notice \'Tracking: Unable to extract user_id from: %. Not able to log this message.\', old.to_addr;
--	 return old;
--   end if;
--   
--   if v_sender_id is null then
--        raise notice \'Tracking: Unknown sender %. Not able to log this message.\', old.from_addr;
--	 return old;
--   end if;
--   
--   -- if TrackAllMails parameter is set to 0 we only track mails from packages that have requests
--
--   select 	into v_track_all_p pv.attr_value 
--		from apm_parameter_values pv, apm_parameters p 
--   where p.parameter_id = pv.parameter_id
--		and p.parameter_name = \'TrackAllMails\'
--   and p.package_key = \'mail-tracking\'
--   limit 1;
--   
--   if v_track_all_p = \'1\' then 
--   
--   perform acs_mail_log__new (
--       	old.message_id, 
--       	v_recepient_id, 
--       	v_sender_id, 
--       	old.package_id, 
--       	old.subject, 
--       	old.body
--       );
--       
--   else
--   	select into v_object_id object_id from acs_mail_tracking_request where object_id = old.package_id;
--   	
--   	if v_object_id is not null then
--
--		raise notice \'Tracking: Logged mail for package_id %.\', v_object_id;
--
--   		perform acs_mail_log__new (
--		        old.message_id, 
--		        v_recepient_id, 
--		        v_sender_id, 
--		        old.package_id, 
--		        old.subject, 
--		        old.body
--       	);
--       else
--		raise notice \'Tracking: No request for package id % and tracking all mails is turned off.\', old.package_id;
--	end if;
--   
--   end if;
--
--    return old;
--   end;
--
-- LANGUAGE 'plpgsql';
--
--
--reate trigger acs_mail_log_tr after delete on acs_mail_lite_queue
--or each row execute procedure acs_mail_log_tr();
--