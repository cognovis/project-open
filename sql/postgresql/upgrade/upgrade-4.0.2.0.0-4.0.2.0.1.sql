

-- Fix metadata from file_storage_object
update acs_object_types set 
	table_name = 'file_storage_objectx', 
	id_column='object_id' 
where 
	object_type = 'file_storage_object'
;


