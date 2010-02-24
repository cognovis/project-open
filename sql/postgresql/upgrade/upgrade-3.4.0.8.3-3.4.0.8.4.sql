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

alter table im_materials add column source_language_id integer constraint im_materials_source_language_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_material', 'source_language_id', 'Source Language', 'translation_languages', 'integer', 'f');

alter table im_materials add column target_language_id integer constraint im_materials_target_language_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_material', 'target_language_id', 'Target Language', 'translation_languages', 'integer', 'f');

alter table im_materials add column subject_area_id integer constraint im_materials_subject_area_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_material', 'subject_area_id', 'Subject Area', 'subject_area', 'integer', 'f');

alter table im_materials add column task_type_id integer constraint im_materials_task_type_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_material', 'task_type_id', 'Task Type', 'translation_languages', 'integer', 'f');

alter table im_materials add column file_type_id integer constraint im_materials_file_type_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_material', 'file_type_id', 'File Type', 'trans_file_types', 'integer', 'f');

