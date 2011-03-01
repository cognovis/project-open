-- file_mapping_table
create table acs_mail_log_attachment_map (
	log_id 			integer
				constraint acs_mail_log_log_id2_fk
				references acs_mail_log(log_id),
	file_id			integer
				constraint acs_mail_log_file_id_fk
				references cr_items(item_id)
);

-- Get the file_ids and insert them into the tracking table

insert into acs_mail_log_attachment_map (log_id, file_id) select r.object_id_one as log_id, o.object_id as file_id 
	from acs_data_links r, acs_objects o, acs_mail_log m
	where r.object_id_two = o.object_id 
	and o.object_type in ('content_item') 
	and r.object_id_one = m.log_id;


insert into acs_mail_log_attachment_map (log_id, file_id) select r.object_id_one as log_id, cr.item_id as file_id 
	from acs_data_links r, acs_objects o, acs_mail_log m, cr_revisions cr
	where r.object_id_two = o.object_id 
	and o.object_id = cr.revision_id
	and o.object_type in ('content_revision') 
	and r.object_id_one = m.log_id;

insert into acs_mail_log_attachment_map (log_id, file_id) select r.object_id_one as log_id, cr.item_id as file_id 
	from acs_data_links r, acs_objects o, acs_mail_log m, cr_revisions cr
	where r.object_id_two = o.object_id 
	and o.object_id = cr.revision_id
	and o.object_type in ('file_storage_object') 
	and r.object_id_one = m.log_id;

insert into acs_mail_log_attachment_map (log_id, file_id) select r.object_id_one as log_id, cr.item_id as file_id 
	from acs_data_links r, acs_objects o, acs_mail_log m, cr_revisions cr
	where r.object_id_two = o.object_id 
	and o.object_id = cr.revision_id
	and o.object_type in ('image') 
	and r.object_id_one = m.log_id;

alter table acs_mail_log drop constraint acs_mail_log_object_id_fk;
create or replace function acs_mail_log__new (integer,varchar, integer, integer, varchar, varchar,integer,varchar,varchar,varchar)
returns integer as '
declare	
	p_log_id alias for $1;
	p_message_id alias for $2;
	p_sender_id alias for $3;
	p_package_id alias for $4;
	p_subject alias for $5;
	p_body alias for $6;
	p_object_id alias for $7;
	p_cc alias for $8;
	p_bcc alias for $9;
	p_to_addr alias for $10;
begin
	insert into acs_mail_log
		(log_id, message_id, sender_id, package_id, subject, body, sent_date, object_id, cc, bcc, to_addr)
	values
		(p_log_id, p_message_id, p_sender_id, p_package_id, p_subject, p_body, now(), p_object_id, p_cc, p_bcc, p_to_addr);

	return p_log_id;

end;' language 'plpgsql';
