--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @author Michael Steigman (michael@steigman.net)
-- @creation-date 2003-04-16
--

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

create or replace function category_tree__new_translation (
    integer,   -- tree_id
    varchar,   -- locale
    varchar,   -- tree_name
    varchar,   -- description
    timestamp with time zone, -- modifying_date
    integer,   -- modifying_user
    varchar    -- modifying_ip
)
returns integer as '
declare
    p_tree_id                alias for $1;
    p_locale                 alias for $2;
    p_tree_name              alias for $3;
    p_description            alias for $4;
    p_modifying_date         alias for $5;
    p_modifying_user         alias for $6;
    p_modifying_ip           alias for $7;
begin
	insert into category_tree_translations
	    (tree_id, locale, name, description)
	values
	    (p_tree_id, p_locale, p_tree_name, p_description);

	update acs_objects
	set last_modified = p_modifying_date,
	    modifying_user = p_modifying_user,
	    modifying_ip = p_modifying_ip
	where object_id = p_tree_id;
        return 0;
end;
' language 'plpgsql';

create or replace function category_tree__del (
    integer   -- tree_id
)
returns integer as '
declare
    p_tree_id                alias for $1;
begin

       delete from category_tree_map where tree_id = p_tree_id;

       delete from category_object_map where category_id in (select category_id from categories where tree_id = p_tree_id);

       delete from category_translations where category_id in (select category_id from categories where tree_id = p_tree_id);
 
       delete from categories where tree_id = p_tree_id;
 
       delete from acs_objects where context_id = p_tree_id;

       delete from acs_permissions where object_id = p_tree_id;

       delete from category_tree_translations where tree_id  = p_tree_id;
       delete from category_trees where tree_id  = p_tree_id;
 
       perform acs_object__delete(p_tree_id);

       return 0;
end;
' language 'plpgsql';

create or replace function category_tree__edit (
    integer,   -- tree_id
    varchar,   -- locale
    varchar,   -- tree_name
    varchar,   -- description
    char,      -- site_wide_p
    timestamp with time zone, -- modifying_date
    integer,   -- modifying_user
    varchar    -- modifying_ip
)
returns integer as '
declare
    p_tree_id                alias for $1;
    p_locale                 alias for $2;
    p_tree_name              alias for $3;
    p_description            alias for $4;
    p_site_wide_p            alias for $5;
    p_modifying_date         alias for $6;
    p_modifying_user         alias for $7;
    p_modifying_ip           alias for $8;
begin
	update category_trees
	set site_wide_p = p_site_wide_p
	where tree_id = p_tree_id;

	update category_tree_translations
	set name = p_tree_name,
	    description = p_description
	where tree_id = p_tree_id
	and locale = p_locale;

	update acs_objects
	set last_modified = p_modifying_date,
	    modifying_user = p_modifying_user,
	    modifying_ip = p_modifying_ip
	where object_id = p_tree_id;

       return 0;
end;
' language 'plpgsql';

create or replace function category_tree__copy (
    integer,   -- source_tree
    integer,   -- dest_tree
    integer,   -- creation_user
    varchar    -- creation_ip
)
returns integer as '
declare
    p_source_tree           alias for $1;
    p_dest_tree             alias for $2;
    p_creation_user         alias for $3;
    p_creation_ip           alias for $4;

    v_new_left_ind          integer;
    v_category_id	    integer;
    source record;
begin
	select coalesce(max(right_ind),0) into v_new_left_ind 
	from categories
	where tree_id = p_dest_tree;

	for source in (select category_id, parent_id, left_ind, right_ind from categories where tree_id = p_source_tree) loop

	   v_category_id := acs_object__new ( 
                null,
		''category'',     -- object_type
		now(),            -- creation_date
		p_creation_user,  -- creation_user
		p_creation_ip,    -- creation_ip
	  	p_dest_tree       -- context_id
	   );

	   insert into categories
	   (category_id, tree_id, parent_id, left_ind, right_ind)
	   values
	   (v_category_id, p_dest_tree, source.parent_id, source.left_ind + v_new_left_ind, source.right_ind + v_new_left_ind);
	end loop;

	-- correct parent_ids
	update categories
	set parent_id = (select t.category_id
			from categories s, categories t
			where s.category_id = categories.parent_id
			and t.tree_id = p_dest_tree
			and s.left_ind + v_new_left_ind = t.left_ind)
	where tree_id = p_dest_tree;

	-- copy all translations
	insert into category_translations
	(category_id, locale, name, description)
	(select ct.category_id, t.locale, t.name, t.description
	from category_translations t, categories cs, categories ct
	where ct.tree_id = p_dest_tree
	and cs.tree_id = p_source_tree
	and cs.left_ind + v_new_left_ind = ct.left_ind
	and t.category_id = cs.category_id);

	-- for debugging reasons
	perform category_tree__check_nested_ind(p_dest_tree);

       return 0;
end;
' language 'plpgsql';

create or replace function category_tree__map (
    integer,   -- object_id
    integer,   -- tree_id
    integer,   -- subtree_category_id
    char,      -- assign_single_p
    char,      -- require_category_p
    varchar    -- widget
)
returns integer as '
declare
    p_object_id              alias for $1;
    p_tree_id                alias for $2;
    p_subtree_category_id    alias for $3;
    p_assign_single_p        alias for $4;
    p_require_category_p     alias for $5;
    p_widget                 alias for $6;

    v_map_count              integer;
begin
	select count(*) 
	into v_map_count
	from category_tree_map
	where object_id = p_object_id
	and tree_id = p_tree_id;

	if v_map_count = 0 then
	   insert into category_tree_map
	   (tree_id, subtree_category_id, object_id,
	    assign_single_p, require_category_p, widget)
	   values (p_tree_id, p_subtree_category_id, p_object_id,
	           p_assign_single_p, p_require_category_p, p_widget);
	end if;
        return 0;
end;
' language 'plpgsql';

create or replace function category_tree__unmap (
    integer,   -- object_id
    integer   -- tree_id
)
returns integer as '
declare
    p_object_id              alias for $1;
    p_tree_id                alias for $2;
begin
	delete from category_tree_map
	where object_id = p_object_id
	and tree_id = p_tree_id;
        return 0;
end;
' language 'plpgsql';

create or replace function category_tree__name (
    integer   -- tree_id
)
returns varchar as '
declare
    p_tree_id                alias for $1;
    v_name                   varchar;
begin
	select name into v_name
	from category_tree_translations
	where tree_id = p_tree_id
	and locale = ''en_US'';

	return v_name;
end;
' language 'plpgsql';

create or replace function category_tree__check_nested_ind (
    integer   -- tree_id
)
returns integer as '
declare
    p_tree_id                alias for $1;
    v_negative               numeric;
    v_order                  numeric;
    v_parent                 numeric;
begin
        select count(*) into v_negative from categories
	where tree_id = p_tree_id and (left_ind < 1 or right_ind < 1);

	if v_negative > 0 then 
           raise EXCEPTION ''-20001: negative index not allowed!'';
        end if;

        select count(*) into v_order from categories
	where tree_id = p_tree_id
	and left_ind >= right_ind;
	
	if v_order > 0 then 
           raise EXCEPTION ''-20002: right index must be greater than left index!'';
        end if;

        select count(*) into v_parent
	from categories parent, categories child
		where parent.tree_id = p_tree_id
		and child.tree_id = parent.tree_id
		and (parent.left_ind >= child.left_ind or parent.right_ind <= child.right_ind)
		and child.parent_id = parent.category_id;

	if v_parent > 0 then 
           raise EXCEPTION ''-20003: child index must be between parent index!'';
        end if;

        return 0;
end;
' language 'plpgsql';
