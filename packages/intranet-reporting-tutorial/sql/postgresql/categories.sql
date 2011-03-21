------------------------------------------------------------
-- Categories
------------------------------------------------------------

-- Get everything about a category (simple)
select  c.*
from    im_categories c
where   c.category_id = :category_id
;


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

-- Get the parents of category_id
select	h.* 
from	im_category_hierarchy h 
where	child_id = :category_id;


-- Determine if the type of a Project is a subtype
-- of a certain category.
-- This snippet shows that the category_hierarchy
-- contains the "transitive closure", so that you
-- don't need a hierarchical query.
select  count(*)
from
	im_projects p,
	im_categories c,
	im_category_hierarchy h
where
	p.project_id = :project_id
	and c.category = :project_type
	and (
		p.project_type_id = c.category_id
	or
		p.project_type_id = h.child_id
		and h.parent_id = c.category_id
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


-------------------------------------------------------------
-- Categories
--
-- we use categories as a universal storage for business
-- object states and types, instead of a zillion of 
-- tables like 'im_project_status' and 'im_project_type'.

create sequence im_categories_seq start 100000;
create table im_categories (
	category_id		integer 
				constraint im_categories_pk
				primary key,
	category		varchar(50) not null,
	category_description	text,
	category_type		varchar(50),
	category_gif		varchar(100) default 'category',
	enabled_p		char(1) default 't'
				constraint im_enabled_p_ck
				check(enabled_p in ('t','f')),
				-- used to indicate "abstract" super-categorys
				-- that are not valid values for objects.
				-- For example: "Translation Project" is not a
				-- project_type, but a class of project_types.
	parent_only_p		char(1) default 'f'
				constraint im_parent_only_p_ck
				check(parent_only_p in ('t','f'))
);

-- optional system to put categories in a hierarchy.
-- This table stores the "transitive closure" of the
-- is-a relationship between categories in a kind of matrix.
-- Let's asume: B isa A and C isa B. So we'll store
-- the tupels (C,A), (C,B) and (B,A).
--
-- This structure is a very fast structure for asking:
--
--	"is category A a subcategory of B?"
--
-- but requires n^2 storage space in the worst case and
-- it's a mess retracting settings from the hierarchy.
-- We won't have very deep hierarchies, so storage complexity
-- is not going to be a problem.

create table im_category_hierarchy (
	parent_id		integer
				constraint im_parent_category_fk
				references im_categories,
	child_id		integer
				constraint im_child_category_fk
				references im_categories,
				constraint category_hierarchy_un 
				unique (parent_id, child_id)
);
