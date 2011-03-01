--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

CREATE or REPLACE PACKAGE category AS
    FUNCTION new ( 
        category_id         in categories.category_id%TYPE		default null,
        tree_id		    in categories.tree_id%TYPE			default null,
        locale		    in category_translations.locale%TYPE,
	name		    in category_translations.name%TYPE,
	description	    in category_translations.description%TYPE,
	parent_id           in categories.parent_id%TYPE		default null,
        deprecated_p        in categories.deprecated_p%TYPE		default 'f',
	object_type         in acs_object_types.object_type%TYPE	default 'category',
	creation_date       in acs_objects.creation_date%TYPE		default sysdate,
	creation_user       in acs_objects.creation_user%TYPE		default null,
	creation_ip         in acs_objects.creation_ip%TYPE		default null
    ) RETURN integer;

    PROCEDURE new_translation ( 
        category_id         in categories.category_id%TYPE,
        locale		    in category_translations.locale%TYPE,
	name		    in category_translations.name%TYPE,
	description	    in category_translations.description%TYPE,
	modifying_date	in acs_objects.last_modified%TYPE	default sysdate,
	modifying_user	in acs_objects.creation_user%TYPE	default null,
	modifying_ip	in acs_objects.creation_ip%TYPE		default null
    );

    PROCEDURE del ( 
	category_id	in categories.category_id%TYPE 
    );
   
    PROCEDURE phase_out (
        category_id	in categories.category_id%TYPE
    );
 
    PROCEDURE phase_in (
        category_id	in categories.category_id%TYPE
    );
 
    PROCEDURE edit (
        category_id	in categories.category_id%TYPE, 
        locale		in category_translations.locale%TYPE,
        name		in category_translations.name%TYPE,
        description	in category_translations.description%TYPE,
	modifying_date	in acs_objects.last_modified%TYPE	default sysdate,
	modifying_user	in acs_objects.creation_user%TYPE	default null,
	modifying_ip	in acs_objects.creation_ip%TYPE		default null
    );

    PROCEDURE change_parent (
	category_id	in categories.category_id%TYPE,
	tree_id		in categories.tree_id%TYPE,
	parent_id	in categories.category_id%TYPE default null
    );

    FUNCTION name (
	category_id	in categories.category_id%TYPE
    ) return varchar2;
END;
/
show errors

CREATE OR REPLACE PACKAGE BODY CATEGORY AS

    FUNCTION new ( 
        category_id         in categories.category_id%TYPE		default null,
        tree_id		    in categories.tree_id%TYPE			default null,
        locale		    in category_translations.locale%TYPE,
	name		    in category_translations.name%TYPE,
	description	    in category_translations.description%TYPE,
	parent_id           in categories.parent_id%TYPE		default null,
        deprecated_p        in categories.deprecated_p%TYPE		default 'f',
	object_type         in acs_object_types.object_type%TYPE	default 'category',
	creation_date       in acs_objects.creation_date%TYPE		default sysdate,
	creation_user       in acs_objects.creation_user%TYPE		default null,
	creation_ip         in acs_objects.creation_ip%TYPE		default null
    ) RETURN integer
    IS  
        v_category_id	integer; 
	v_left_ind	integer;
	v_right_ind	integer;
    BEGIN
	v_category_id := acs_object.new ( 
		object_id     => category_id,
		object_type   => 'category',
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip   => creation_ip,
		context_id    => tree_id,
                title         => name
	);

	if (new.parent_id is null) then
		select 1, nvl(max(right_ind)+1,1) into v_left_ind, v_right_ind
		from categories
		where tree_id = new.tree_id;
	else
		select left_ind, right_ind into v_left_ind, v_right_ind
		from categories
		where category_id = new.parent_id;
	end if;

 	insert into categories
        (category_id, tree_id, deprecated_p, parent_id, left_ind, right_ind)
	values
	(v_category_id, new.tree_id, new.deprecated_p, new.parent_id, -1, -2);

	-- move right subtrees to make room for new category
	update categories
	set left_ind = left_ind + 2,
	    right_ind = right_ind + 2
	where tree_id = new.tree_id
	and left_ind > v_right_ind;

	-- expand upper nodes to make room for new category
	update categories
	set right_ind = right_ind + 2
	where tree_id = new.tree_id
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
	    (v_category_id, locale, name, description);

	return v_category_id;
    END new;


    PROCEDURE new_translation ( 
        category_id         in categories.category_id%TYPE,
        locale		    in category_translations.locale%TYPE,
	name		    in category_translations.name%TYPE,
	description	    in category_translations.description%TYPE,
	modifying_date	in acs_objects.last_modified%TYPE	default sysdate,
	modifying_user	in acs_objects.creation_user%TYPE	default null,
	modifying_ip	in acs_objects.creation_ip%TYPE		default null
    ) IS
    BEGIN
	insert into category_translations
	    (category_id, locale, name, description)
	values
	    (category_id, locale, name, description);

	update acs_objects
        set last_modified = new_translation.modifying_date,
	    modifying_user = new_translation.modifying_user,
	    modifying_ip = new_translation.modifying_ip
	where object_id = new_translation.category_id;

    END new_translation;


    PROCEDURE phase_out (
        category_id	in categories.category_id%TYPE
    ) IS
    BEGIN 
       update categories
       set deprecated_p = 't'
       where category_id = phase_out.category_id;
    END phase_out;
 

    PROCEDURE phase_in (
        category_id	in categories.category_id%TYPE
    ) IS
    BEGIN 
       update categories
       set deprecated_p = 'f'
       where category_id = phase_in.category_id;
    END phase_in;
 

    PROCEDURE del ( 
	category_id	in categories.category_id%TYPE 
    )
    IS
	v_tree_id   integer;
	v_left_ind  integer;
	v_right_ind integer;
    BEGIN
        select tree_id, left_ind, right_ind
	into v_tree_id, v_left_ind, v_right_ind
	from categories where category_id = category.del.category_id;

	for node in (select category_id
		from categories
		where tree_id = v_tree_id
		and left_ind >= v_left_ind
		and right_ind <= v_right_ind) loop

	   delete from category_object_map where category_id = node.category_id;
	   delete from category_translations where category_id = node.category_id;
	   delete from categories where category_id = node.category_id;
	   acs_object.del(node.category_id);
	end loop;

	update categories
	set right_ind = right_ind - (1 + v_right_ind - v_left_ind)
	where left_ind <= v_left_ind
	and right_ind > v_left_ind
	and tree_id = v_tree_id;

	update categories
	set right_ind = right_ind - (1 + v_right_ind - v_left_ind),
	    left_ind = left_ind - (1 + v_right_ind - v_left_ind)
	where left_ind > v_left_ind
	and tree_id = v_tree_id;
	
        -- for debugging reasons
        category_tree.check_nested_ind(v_tree_id);
    END del;


    PROCEDURE edit (
        category_id	in categories.category_id%TYPE, 
        locale		in category_translations.locale%TYPE,
	name		in category_translations.name%TYPE,
        description	in category_translations.description%TYPE,
	modifying_date	in acs_objects.last_modified%TYPE	default sysdate,
	modifying_user	in acs_objects.creation_user%TYPE	default null,
	modifying_ip	in acs_objects.creation_ip%TYPE		default null
    ) IS
    BEGIN

	-- change category name
	update category_translations
	set name = edit.name,
            description = edit.description
      where category_id = edit.category_id
        and locale = edit.locale;

	update acs_objects
        set last_modified = edit.modifying_date,
	    modifying_user = edit.modifying_user,
	    modifying_ip = edit.modifying_ip
      where object_id = edit.category_id;

    END edit;


    PROCEDURE change_parent (
	category_id	in categories.category_id%TYPE,
	tree_id		in categories.tree_id%TYPE,
	parent_id	in categories.category_id%TYPE default null
    )
    IS
	v_old_left_ind integer;
	v_old_right_ind integer;
	v_new_left_ind integer;
	v_new_right_ind integer;
	v_width integer;
    BEGIN
 	update categories
	set parent_id = change_parent.parent_id
	where category_id = change_parent.category_id;

	-- first save the subtree, then compact tree, then expand tree to make room
	-- for subtree, then insert it

	select left_ind, right_ind into v_old_left_ind, v_old_right_ind
	from categories
	where category_id = change_parent.category_id;

	v_width := v_old_right_ind - v_old_left_ind + 1;

	-- cut out old subtree
	update categories
	set left_ind = -left_ind, right_ind = -right_ind
	where tree_id = change_parent.tree_id
	and left_ind >= v_old_left_ind
	and right_ind <= v_old_right_ind;

	-- compact parent trees
	update categories
	set right_ind = right_ind - v_width
	where tree_id = change_parent.tree_id
	and left_ind < v_old_left_ind
	and right_ind > v_old_right_ind;

	-- compact right tree portion
	update categories
	set left_ind = left_ind - v_width,
	right_ind = right_ind - v_width
	where tree_id = change_parent.tree_id
	and left_ind > v_old_left_ind;

	if (change_parent.parent_id is null) then
	   select 1, max(right_ind)+1 into v_new_left_ind, v_new_right_ind
	   from categories
	   where tree_id = change_parent.tree_id;
	else
	   select left_ind, right_ind into v_new_left_ind, v_new_right_ind
	   from categories
	   where category_id = change_parent.parent_id;
	end if;

	-- move parent trees to make room
	update categories
	set right_ind = right_ind + v_width
	where tree_id = change_parent.tree_id
	and left_ind <= v_new_left_ind
	and right_ind >= v_new_right_ind;

	-- move right tree portion to make room
	update categories
	set left_ind = left_ind + v_width,
	right_ind = right_ind + v_width
	where tree_id = change_parent.tree_id
	and left_ind > v_new_right_ind;

	-- insert subtree at correct place
	update categories
	set left_ind = -left_ind + (v_new_right_ind - v_old_left_ind),
	right_ind = -right_ind + (v_new_right_ind - v_old_left_ind)
	where tree_id = change_parent.tree_id
	and left_ind < 0;

	-- for debugging reasons
        category_tree.check_nested_ind(change_parent.tree_id);
    END change_parent;


    FUNCTION name (
	category_id	in categories.category_id%TYPE
    ) return varchar2
    IS
	v_name	category_translations.name%TYPE;
    BEGIN
	select name into v_name
	from category_translations
	where category_id = name.category_id
	and locale = 'en_US';

	return v_name;
    END name;

END category;
/
show errors
