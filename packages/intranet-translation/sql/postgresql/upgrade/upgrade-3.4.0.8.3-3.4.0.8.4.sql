--  upgrade-3.4.0.8.3-3.4.0.8.4.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.3-3.4.0.8.4.sql','');


-- Replace the hardcoded workflows stages by information
-- in the aux_string1 field of translation tasks.

update im_categories set aux_string1 = 'trans edit'	where category_id = 87;
update im_categories set aux_string1 = 'edit'		where category_id = 88;
update im_categories set aux_string1 = 'trans edit proof' where category_id = 89;
update im_categories set aux_string1 = 'other'		where category_id = 90;
update im_categories set aux_string1 = 'other'		where category_id = 91;
update im_categories set aux_string1 = 'other'		where category_id = 92;
update im_categories set aux_string1 = 'trans'		where category_id = 93;
update im_categories set aux_string1 = 'trans edit'	where category_id = 94;
update im_categories set aux_string1 = 'proof'		where category_id = 95;
update im_categories set aux_string1 = 'other'		where category_id = 96;



-----------------------------------------------------------
-- DynField Widgets
-----------------------------------------------------------

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'trans_task_types', 'Translation Task Types', 'Translation Task Types',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Translation Task Type"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'trans_file_types', 'Translation File Types', 'Translation File Types',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Translation File Type"}}'
);

-----------------------------------------------------------
-- DynFields for im_material
-----------------------------------------------------------

create or replace function im_insert_acs_object_type_tables (varchar, varchar, varchar)
returns integer as $body$
DECLARE
        p_object_type           alias for $1;
        p_table_name            alias for $2;
        p_id_column             alias for $3;

        v_count                 integer;
BEGIN
        -- Check for duplicates
        select  count(*) into v_count
        from    acs_object_type_tables
        where   object_type = p_object_type and
                table_name = p_table_name;
        IF v_count > 0 THEN return 1; END IF;

        -- Make sure the object_type exists
        select  count(*) into v_count
        from    acs_object_types
        where   object_type = p_object_type;
        IF v_count = 0 THEN return 2; END IF;

        insert into acs_object_type_tables (object_type, table_name, id_column)
        values (p_object_type, p_table_name, p_id_column);

        return 0;
end;$body$ language 'plpgsql';


-- make sure the acs_object_type_tables entry is there.
SELECT im_insert_acs_object_type_tables('im_material','im_materials','material_id');




create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_materials' and lower(column_name) = 'source_language_id';
	IF v_count = 0 THEN 
		alter table im_materials add column source_language_id integer 
		constraint im_materials_source_language_fk references im_categories;
	END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_materials' and lower(column_name) = 'target_language_id';
	IF v_count = 0 THEN 
		alter table im_materials add column target_language_id integer 
		constraint im_materials_target_language_fk references im_categories;
	END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_materials' and lower(column_name) = 'subject_area_id';
	IF v_count = 0 THEN 
		alter table im_materials add column subject_area_id integer 
		constraint im_materials_subject_area_fk references im_categories;
	END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_materials' and lower(column_name) = 'task_type_id';
	IF v_count = 0 THEN 
		alter table im_materials add column task_type_id integer 
		constraint im_materials_task_type_fk references im_categories;
	END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_materials' and lower(column_name) = 'file_type_id';
	IF v_count = 0 THEN 
		alter table im_materials add column file_type_id integer 
		constraint im_materials_file_type_fk references im_categories;
	END IF;

	RETURN 0;
end; $body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_dynfield_attribute_new ('im_material', 'source_language_id', 'Source Language', 'translation_languages', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_material', 'target_language_id', 'Target Language', 'translation_languages', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_material', 'subject_area_id', 'Subject Area', 'subject_area', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_material', 'task_type_id', 'Task Type', 'translation_languages', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_material', 'file_type_id', 'File Type', 'trans_file_types', 'integer', 'f');

