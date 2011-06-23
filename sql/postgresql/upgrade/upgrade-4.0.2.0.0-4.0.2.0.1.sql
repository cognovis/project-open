

-- Fix metadata from file_storage_object
update acs_object_types set 
	table_name = 'file_storage_objectx', 
	id_column='object_id' 
where 
	object_type = 'file_storage_object'
;



delete from cr_text;
alter table cr_text disable trigger cr_text_tr;
insert into cr_text (text_data) values ('');
alter table cr_text enable trigger cr_text_tr;
