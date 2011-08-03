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




-- Select out the lowest parent of the category.
-- This makes sense as a fast approximation, but 
-- isn't correct. 
-- ToDo: Pull out the real top-level parent
--
create or replace function im_category_min_parent (
	integer
) returns integer as $body$
declare
	p_cat			alias for $1;
	v_cat			integer;
BEGIN
	select	min(c.category_id) into v_cat
	from	im_categories c,
		im_category_hierarchy h
	where	c.category_id = h.parent_id and
		h.child_id = p_cat and
		(c.enabled_p = 't' OR c.enabled_p is NULL);

	RETURN v_cat;
end;$body$ language 'plpgsql';


