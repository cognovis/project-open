-- upgrade-4.0.2.0.4-4.0.2.0.5.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.2.0.4-4.0.2.0.5.sql','');


-- Create a fake object type, because im_categories does not "reference" acs_objects.
select acs_object_type__create_type (
	'im_category',		-- object_type
	'PO Category',		-- pretty_name
	'PO Categories',	-- pretty_plural
	'acs_object',		-- supertype
	'im_categories',	-- table_name
	'category_id',		-- id_column
	'intranet-core',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_category_from_id'	-- name_method
);

