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

