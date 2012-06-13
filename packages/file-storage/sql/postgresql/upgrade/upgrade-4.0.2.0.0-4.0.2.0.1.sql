-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/file-storage/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');


-- Fix metadata from file_storage_object
update acs_object_types set 
	table_name = 'file_storage_objectx', 
	id_column='object_id',
	name_method = 'file_storage_object__name'
where 
	object_type = 'file_storage_object'
;


create or replace function file_storage_object__name(integer)
returns varchar as $body$
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'cr_text';
	IF 0 = v_count THEN return 1; END IF;

	delete from cr_text;

	select	count(*) into v_count from pg_trigger 
	where	lower(tgname) = 'cr_text_tr';
	IF 0 = v_count THEN
		insert into cr_text (text_data) values ('');
	ELSE
		alter table cr_text disable trigger cr_text_tr;
		insert into cr_text (text_data) values ('');
		alter table cr_text enable trigger cr_text_tr;
	END IF;

	RETURN 0;
END; $body$ language 'plpgsql';



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

