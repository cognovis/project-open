

-- Fix metadata from file_storage_object
update acs_object_types set 
	table_name = 'file_storage_objectx', 
	id_column='object_id',
	name_method = 'file_storage_object__name'
where 
	object_type = 'file_storage_object'
;



delete from cr_text;
alter table cr_text disable trigger cr_text_tr;
insert into cr_text (text_data) values ('');
alter table cr_text enable trigger cr_text_tr;



create or replace function file_storage_object__name(integer)
returns varchar as $body$
DECLARE
        p_item_id               alias for $1;
        v_name                  varchar;
BEGIN
        select  name into v_name
        from    file_storage_objectx
        where   object_id = p_item_id;

        return v_name;
end; $body$ language 'plpgsql';

