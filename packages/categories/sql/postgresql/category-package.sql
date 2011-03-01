--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

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

create or replace function category__new_translation (
    integer,   -- category_id
    varchar,   -- locale
    varchar,   -- name
    varchar,   -- description
    timestamp with time zone, -- modifying_date
    integer,   -- modifying_user
    varchar    -- modifying_ip
)
returns integer as '
declare
    p_category_id       alias for $1;
    p_locale            alias for $2;
    p_name              alias for $3;
    p_description       alias for $4;
    p_modifying_date    alias for $5;
    p_modifying_user    alias for $6;
    p_modifying_ip      alias for $7;
begin
        insert into category_translations
	    (category_id, locale, name, description)
	values
	    (p_category_id, p_locale, p_name, p_description);

	update acs_objects
        set last_modified = p_modifying_date,
	    modifying_user = p_modifying_user,
	    modifying_ip = p_modifying_ip
	where object_id = p_category_id;
        
        return 0;
end;
' language 'plpgsql';

create or replace function category__phase_out (
    integer   -- category_id
)
returns integer as '
declare
    p_category_id       alias for $1;
begin
       update categories
       set deprecated_p = ''t''
       where category_id = p_category_id;

       return 0;
end;
' language 'plpgsql';

create or replace function category__phase_in (
    integer   -- category_id
)
returns integer as '
declare
    p_category_id       alias for $1;
begin
       update categories
       set deprecated_p = ''f''
       where category_id = p_category_id;

       return 0;
end;
' language 'plpgsql';

create or replace function category__del (
    integer   -- category_id
)
returns integer as '
declare
        p_category_id   alias for $1;

        v_tree_id       integer;
	v_left_ind      integer;
	v_right_ind     integer;
        node            record;
begin
        select tree_id, left_ind, right_ind
	into v_tree_id, v_left_ind, v_right_ind
	from categories where category_id = p_category_id;

	for node in 
           select category_id
	     from categories
	    where tree_id = v_tree_id
	      and left_ind >= v_left_ind
	      and right_ind <= v_right_ind 
        loop
	   delete from category_object_map where category_id = node.category_id;
	   delete from category_translations where category_id = node.category_id;
	   delete from categories where category_id = node.category_id;
	   perform acs_object__delete(node.category_id);
	end loop;

	update categories
	set right_ind = (right_ind - (1 + v_right_ind - v_left_ind))
	where left_ind <= v_left_ind
	and right_ind > v_left_ind
	and tree_id = v_tree_id;

	update categories
	set right_ind = (right_ind - (1 + v_right_ind - v_left_ind)),
	    left_ind = (left_ind - (1 + v_right_ind - v_left_ind))
	where left_ind > v_left_ind
	and tree_id = v_tree_id;
	
        -- for debugging reasons
        perform category_tree__check_nested_ind(v_tree_id);
        return 0;
end;
' language 'plpgsql';

create or replace function category__edit (
    integer,   -- category_id
    varchar,   -- locale
    varchar,   -- name
    varchar,   -- description
    timestamp with time zone, -- modifying_date
    integer,   -- modifying_user
    varchar    -- modifying_ip
)
returns integer as '
declare
    p_category_id       alias for $1;
    p_locale            alias for $2;
    p_name              alias for $3;
    p_description       alias for $4;
    p_modifying_date    alias for $5;
    p_modifying_user    alias for $6;
    p_modifying_ip      alias for $7;
begin
	-- change category name
    update category_translations
    set name = p_name,
       description = p_description
    where category_id = p_category_id
          and locale = p_locale;

    update acs_objects
    set last_modified = p_modifying_date,
	    modifying_user = p_modifying_user,
	    modifying_ip = p_modifying_ip
    where object_id = p_category_id;

    return 0;
end;
' language 'plpgsql';

create or replace function category__change_parent (
    integer,   -- category_id
    integer,   -- tree_id
    integer    -- parent_id
)
returns integer as '
declare
    p_category_id       alias for $1;
    p_tree_id           alias for $2;
    p_parent_id         alias for $3;

    v_old_left_ind      integer;
    v_old_right_ind     integer;
    v_new_left_ind      integer;
    v_new_right_ind     integer;
    v_width             integer;
begin
 	update categories
	set parent_id = p_parent_id
	where category_id = p_category_id;

	-- first save the subtree, then compact tree, then expand tree to make room
	-- for subtree, then insert it

	select left_ind, right_ind into v_old_left_ind, v_old_right_ind
	from categories
	where category_id = p_category_id;

	v_width := v_old_right_ind - v_old_left_ind + 1;

	-- cut out old subtree
	update categories
	set left_ind = -left_ind, right_ind = -right_ind
	where tree_id = p_tree_id
	and left_ind >= v_old_left_ind
	and right_ind <= v_old_right_ind;

	-- compact parent trees
	update categories
	set right_ind = right_ind - v_width
	where tree_id = p_tree_id
	and left_ind < v_old_left_ind
	and right_ind > v_old_right_ind;

	-- compact right tree portion
	update categories
	set left_ind = left_ind - v_width,
	right_ind = right_ind - v_width
	where tree_id = p_tree_id
	and left_ind > v_old_left_ind;

	if (p_parent_id is null) then
	   select 1, max(right_ind)+1 into v_new_left_ind, v_new_right_ind
	   from categories
	   where tree_id = p_tree_id;
	else
	   select left_ind, right_ind into v_new_left_ind, v_new_right_ind
	   from categories
	   where category_id = p_parent_id;
	end if;

	-- move parent trees to make room
	update categories
	set right_ind = right_ind + v_width
	where tree_id = p_tree_id
	and left_ind <= v_new_left_ind
	and right_ind >= v_new_right_ind;

	-- move right tree portion to make room
	update categories
	set left_ind = left_ind + v_width,
	right_ind = right_ind + v_width
	where tree_id = p_tree_id
	and left_ind > v_new_right_ind;

	-- insert subtree at correct place
	update categories
	set left_ind = -left_ind + (v_new_right_ind - v_old_left_ind),
	right_ind = -right_ind + (v_new_right_ind - v_old_left_ind)
	where tree_id = p_tree_id
	and left_ind < 0;

	-- for debugging reasons
        perform category_tree__check_nested_ind(p_tree_id);

        return 0;
end;
' language 'plpgsql';


create or replace function category__name (
    integer   -- category_id
)
returns integer as '
declare
    p_category_id       alias for $1;
    v_name      varchar;
begin
	select name into v_name
	from category_translations
	where category_id = p_category_id
	and locale = ''en_US'';

        return 0;
end;
' language 'plpgsql';
