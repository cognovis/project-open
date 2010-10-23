-- Populate the title field of acs_objects with the category 
-- name or tree name
--
-- @author Jeff Davis <davis@xarg.net>
-- @creation-date 2005-02-06

create or replace function category__new (
    integer,   -- category_id
    integer,   -- tree_id
    varchar,   -- locale
    varchar,   -- name
    varchar,   -- description
    integer,   -- parent_id
    char,      -- deprecated_p
    timestamp with time zone, -- creation_date
    integer,   -- creation_user
    varchar    -- creation_ip
)
returns integer as '
declare
    p_category_id       alias for $1;
    p_tree_id           alias for $2;
    p_locale            alias for $3;
    p_name              alias for $4;
    p_description       alias for $5;
    p_parent_id         alias for $6;
    p_deprecated_p      alias for $7;
    p_creation_date     alias for $8;
    p_creation_user     alias for $9;
    p_creation_ip       alias for $10;

    v_category_id       integer; 
    v_left_ind          integer;
    v_right_ind         integer;
begin
	v_category_id := acs_object__new ( 
		p_category_id,          -- object_id
		''category'',           -- object_type
		p_creation_date,        -- creation_date
		p_creation_user,        -- creation_user
		p_creation_ip,          -- creation_ip
		p_tree_id,              -- context_id
                ''t'',                  -- security_inherit_p
                p_name,                 -- title
                null                    -- package_id
	);

	if (p_parent_id is null) then
		select 1, coalesce(max(right_ind)+1,1) into v_left_ind, v_right_ind
		from categories
		where tree_id = p_tree_id;
	else
		select left_ind, right_ind into v_left_ind, v_right_ind
		from categories
		where category_id = p_parent_id;
	end if;

 	insert into categories
        (category_id, tree_id, deprecated_p, parent_id, left_ind, right_ind)
	values
	(v_category_id, p_tree_id, p_deprecated_p, p_parent_id, -1, -2);

	-- move right subtrees to make room for new category
	update categories
	set left_ind = left_ind + 2,
	    right_ind = right_ind + 2
	where tree_id = p_tree_id
	and left_ind > v_right_ind;

	-- expand upper nodes to make room for new category
	update categories
	set right_ind = right_ind + 2
	where tree_id = p_tree_id
	and left_ind <= v_left_ind
	and right_ind >= v_right_ind;

	-- insert new category
	update categories
	set left_ind = v_right_ind,
	    right_ind = v_right_ind + 1
	where category_id = v_category_id;

	insert into category_translations
	    (category_id, locale, name, description)
	values
	    (v_category_id, p_locale, p_name, p_description);

	return v_category_id;
end;
' language 'plpgsql';


create or replace function category_tree__new (
    integer, -- tree_id
    varchar, -- locale
    varchar, -- tree_name
    varchar, -- description
    char,    -- site_wide_p
    timestamp with time zone, -- creation_date
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
)
returns integer as '
declare
    p_tree_id               alias for $1;
    p_locale                alias for $2;
    p_tree_name             alias for $3;
    p_description           alias for $4;
    p_site_wide_p           alias for $5;
    p_creation_date         alias for $6;
    p_creation_user         alias for $7;
    p_creation_ip           alias for $8;
    p_context_id            alias for $9;
  
    v_tree_id               integer;
begin
	v_tree_id := acs_object__new (
		p_tree_id,         -- object_id
		''category_tree'', -- object_type
		p_creation_date,   -- creation_date
		p_creation_user,   -- creation_user
		p_creation_ip,     -- creation_ip
		p_context_id,      -- context_id
                p_tree_name,       -- title
                null               -- package_id
	);

	insert into category_trees
	   (tree_id, site_wide_p)
	values
	   (v_tree_id, p_site_wide_p);

	perform acs_permission__grant_permission (
		v_tree_id,             -- object_id
		p_creation_user,       -- grantee_id
		''category_tree_read'' -- privilege
	);
	perform acs_permission__grant_permission (
		v_tree_id,                -- object_id
		p_creation_user,          -- grantee_id
		''category_tree_write''   -- privilege
	);
	perform acs_permission__grant_permission (
		v_tree_id,                          -- object_id
		p_creation_user,                    -- grantee_id
		''category_tree_grant_permissions'' -- privilege
	);

	insert into category_tree_translations
	    (tree_id, locale, name, description)
	values
	    (v_tree_id, p_locale, p_tree_name, p_description);

	return v_tree_id;
end;
' language 'plpgsql';

