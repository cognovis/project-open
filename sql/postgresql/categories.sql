

-- Get everything about categories
-- Categories with duplicate parents (possible) will appear
-- multiple times.
select
	c.*,
	im_category_from_id(aux_int1) as aux_int1_cat,
	im_category_from_id(aux_int2) as aux_int2_cat,
	h.parent_id,
	im_category_from_id(h.parent_id) as parent
from
	im_categories c
		left outer join im_category_hierarchy h
		on (c.category_id = h.child_id)
where
	$category_type_criterion
order by
	category_type,
	category_id
;



-- Get everything about a category (simple)
select  c.*
from    im_categories c
where   c.category_id = :category_id
;


-- Get the parents of category_id
select	h.* 
from	im_category_hierarchy h 
where	child_id = :category_id
;


-- Create a new Category
insert into im_categories (
	category_id, category, category_type,
	category_description, enabled_p,
	aux_int1, aux_int2,
	aux_string1, aux_string2
) values (
	:category_id, :category, :category_type,
	:category_description, :enabled_p,
	:aux_int1, :aux_int2,
	:aux_string1, :aux_string2
);


-- Create a new Category Hierarchy Entry 
insert into im_category_hierarchy (
	parent_id, 
	child_id
) values (
	:parent, 
	:category_id
);


-- Update Categories
UPDATE
	im_categories
SET
	category = :category,
	category_type = :category_type,
	aux_int1 = :aux_int1,
	aux_int2 = :aux_int2,
	aux_string1 = :aux_string1,
	aux_string2 = :aux_string2,
	category_description = :category_description,
	enabled_p = :enabled_p
WHERE
	category_id = :category_id
;
