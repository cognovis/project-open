--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

create or replace package category_tree
as 

    FUNCTION new (
        tree_id		     in category_trees.tree_id%TYPE		 default null,
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
        site_wide_p          in category_trees.site_wide_p%TYPE		 default 'f',
	creation_date        in acs_objects.creation_date%TYPE		 default sysdate,
	creation_user        in acs_objects.creation_user%TYPE		 default null,
	creation_ip          in acs_objects.creation_ip%TYPE		 default null,
	context_id           in acs_objects.context_id%TYPE		 default null
    ) RETURN category_trees.tree_id%TYPE;

    PROCEDURE new_translation (
        tree_id		     in category_trees.tree_id%TYPE,
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
	modifying_date       in acs_objects.last_modified%TYPE		 default sysdate,
	modifying_user       in acs_objects.creation_user%TYPE		 default null,
	modifying_ip         in acs_objects.creation_ip%TYPE		 default null
    );

    PROCEDURE del ( 
	tree_id              in category_trees.tree_id%TYPE 
    );

    PROCEDURE edit (
        tree_id		     in category_trees.tree_id%TYPE		 default null,
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
        site_wide_p          in category_trees.site_wide_p%TYPE		 default 'f',
	modifying_date       in acs_objects.last_modified%TYPE		 default sysdate,
	modifying_user       in acs_objects.creation_user%TYPE		 default null,
	modifying_ip         in acs_objects.creation_ip%TYPE		 default null
    );

    PROCEDURE copy (
	source_tree           in category_trees.tree_id%TYPE,
	dest_tree             in category_trees.tree_id%TYPE,
	creation_user         in acs_objects.creation_user%TYPE		default null, 
	creation_ip           in acs_objects.creation_ip%TYPE		default null
    );

    PROCEDURE map (
	object_id		in acs_objects.object_id%TYPE,
	tree_id			in category_trees.tree_id%TYPE,
	subtree_category_id	in categories.category_id%TYPE		default null,
	assign_single_p		in category_tree_map.assign_single_p%TYPE	default 'f',
	require_category_p	in category_tree_map.require_category_p%TYPE	default 'f',
	widget          	in category_tree_map.widget%TYPE	
    );

    PROCEDURE unmap (
	object_id in acs_objects.object_id%TYPE,
	tree_id   in category_trees.tree_id%TYPE);
    
    FUNCTION name (
	tree_id	in category_trees.tree_id%TYPE
    ) return varchar2;

    PROCEDURE check_nested_ind (tree_id in category_trees.tree_id%TYPE);
end; 
/ 
show errors

create or replace package body category_tree 
as 
    ------------------------------------------------------------
    --	PUBLIC FUNCTIONS and PROCEDURES
    ------------------------------------------------------------
    FUNCTION new (
        tree_id		     in category_trees.tree_id%TYPE	         default null, 
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
        site_wide_p          in category_trees.site_wide_p%TYPE		 default 'f',
	creation_date        in acs_objects.creation_date%TYPE		 default sysdate,
	creation_user        in acs_objects.creation_user%TYPE		 default null,
	creation_ip          in acs_objects.creation_ip%TYPE		 default null,
	context_id           in acs_objects.context_id%TYPE		 default null
    ) RETURN category_trees.tree_id%TYPE
    IS
        v_tree_id integer;
    BEGIN
	v_tree_id := acs_object.new (
		object_id     => tree_id,
		object_type   => 'category_tree',
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip   => creation_ip,
		context_id    => context_id,
                title         => tree_name
	);

	insert into category_trees
	   (tree_id, site_wide_p)
	values
	   (v_tree_id, site_wide_p);

	acs_permission.grant_permission (
		object_id  => v_tree_id,
		grantee_id => creation_user,
		privilege  => 'category_tree_read'
	);
	acs_permission.grant_permission (
		object_id  => v_tree_id,
		grantee_id => creation_user,
		privilege  => 'category_tree_write'
	);
	acs_permission.grant_permission (
		object_id  => v_tree_id,
		grantee_id => creation_user,
		privilege  => 'category_tree_grant_permissions'
	);

	insert into category_tree_translations
	    (tree_id, locale, name, description)
	values
	    (v_tree_id, locale, tree_name, description);

	return v_tree_id;
    END new;


    PROCEDURE new_translation (
        tree_id		     in category_trees.tree_id%TYPE,
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
	modifying_date       in acs_objects.last_modified%TYPE		 default sysdate,
	modifying_user       in acs_objects.creation_user%TYPE		 default null,
	modifying_ip         in acs_objects.creation_ip%TYPE		 default null
    ) IS
    BEGIN
	insert into category_tree_translations
	    (tree_id, locale, name, description)
	values
	    (tree_id, locale, tree_name, description);

	update acs_objects
	set last_modified = new_translation.modifying_date,
	    modifying_user = new_translation.modifying_user,
	    modifying_ip = new_translation.modifying_ip
	where object_id = new_translation.tree_id;
    END new_translation;


    PROCEDURE del ( 
	tree_id         in category_trees.tree_id%TYPE 
    ) 
    IS
    BEGIN 
       delete from category_tree_map where tree_id = category_tree.del.tree_id;

       delete from category_object_map where category_id in (select category_id from categories where tree_id = category_tree.del.tree_id);

       delete from category_translations where category_id in (select category_id from categories where tree_id = category_tree.del.tree_id);
 
       delete from categories where tree_id = category_tree.del.tree_id;
 
       delete from acs_objects where context_id = category_tree.del.tree_id;

       delete from acs_permissions where object_id = category_tree.del.tree_id;

       delete from category_tree_translations where tree_id  = category_tree.del.tree_id;
       delete from category_trees where tree_id  = category_tree.del.tree_id;
 
       acs_object.del(category_tree.del.tree_id);
    END del;


    PROCEDURE edit (
        tree_id		     in category_trees.tree_id%TYPE		 default null,
	locale		     in category_tree_translations.locale%TYPE,
	tree_name	     in category_tree_translations.name%TYPE,
	description	     in category_tree_translations.description%TYPE,
        site_wide_p          in category_trees.site_wide_p%TYPE		 default 'f',
	modifying_date       in acs_objects.last_modified%TYPE		 default sysdate,
	modifying_user       in acs_objects.creation_user%TYPE		 default null,
	modifying_ip         in acs_objects.creation_ip%TYPE		 default null
    ) is
    BEGIN
	update category_trees
	set site_wide_p = edit.site_wide_p
	where tree_id = edit.tree_id;

	update category_tree_translations
	set name = edit.tree_name,
	    description = edit.description
	where tree_id = edit.tree_id
	and locale = edit.locale;

	update acs_objects
	set last_modified = edit.modifying_date,
	    modifying_user = edit.modifying_user,
	    modifying_ip = edit.modifying_ip
	where object_id = edit.tree_id;
    END edit;


    PROCEDURE copy (
	source_tree           in category_trees.tree_id%TYPE,
	dest_tree             in category_trees.tree_id%TYPE,
	creation_user         in acs_objects.creation_user%TYPE		default null, 
	creation_ip           in acs_objects.creation_ip%TYPE		default null
    ) IS 
	v_new_left_ind	categories.left_ind%TYPE;
	v_category_id	categories.category_id%TYPE;
    BEGIN
	select nvl(max(right_ind),0) into v_new_left_ind 
	from categories
	where tree_id = copy.dest_tree;

	for source in (select category_id, parent_id, left_ind, right_ind from categories where tree_id = copy.source_tree) loop

	   v_category_id := acs_object.new ( 
		object_type   => 'category', 
		creation_date => sysdate,
		creation_user => copy.creation_user,
		creation_ip   => copy.creation_ip,
	  	context_id    => copy.dest_tree
	   );

	   insert into categories
	   (category_id, tree_id, parent_id, left_ind, right_ind)
	   values
	   (v_category_id, copy.dest_tree, source.parent_id, source.left_ind + v_new_left_ind, source.right_ind + v_new_left_ind);
	end loop;

	-- correct parent_ids
	update categories c
	set parent_id = (select t.category_id
			from categories s, categories t
			where s.category_id = c.parent_id
			and t.tree_id = copy.dest_tree
			and s.left_ind + v_new_left_ind = t.left_ind)
	where tree_id = copy.dest_tree;

	-- copy all translations
	insert into category_translations
	(category_id, locale, name, description)
	(select ct.category_id, t.locale, t.name, t.description
	from category_translations t, categories cs, categories ct
	where ct.tree_id = copy.dest_tree
	and cs.tree_id = copy.source_tree
	and cs.left_ind + v_new_left_ind = ct.left_ind
	and t.category_id = cs.category_id);

	-- for debugging reasons
	check_nested_ind(dest_tree);
    END copy;


    PROCEDURE map (
	object_id		in acs_objects.object_id%TYPE,
	tree_id			in category_trees.tree_id%TYPE,
	subtree_category_id	in categories.category_id%TYPE		default null,
	assign_single_p		in category_tree_map.assign_single_p%TYPE	default 'f',
	require_category_p	in category_tree_map.require_category_p%TYPE	default 'f',
	widget			in category_tree_map.widget%TYPE
    ) is
	v_map_count integer;
    BEGIN
	select count(*) 
	into v_map_count
	from category_tree_map
	where object_id = map.object_id
	and tree_id = map.tree_id;

	if v_map_count = 0 then
	   insert into category_tree_map
	   (tree_id, subtree_category_id, object_id, assign_single_p, require_category_p,widget)
	   values (map.tree_id, map.subtree_category_id, map.object_id,
	           map.assign_single_p, map.require_category_p,map.widget);
	end if;

    END map;


    PROCEDURE unmap (
	object_id in acs_objects.object_id%TYPE,
	tree_id   in category_trees.tree_id%TYPE
    ) IS
    BEGIN
	delete from category_tree_map
	where object_id = unmap.object_id
	and tree_id = unmap.tree_id;
    END unmap;


    FUNCTION name (
	tree_id	in category_trees.tree_id%TYPE
    ) return varchar2
    IS
	v_name	category_tree_translations.name%TYPE;
    BEGIN
	select name into v_name
	from category_tree_translations
	where tree_id = name.tree_id
	and locale = 'en_US';

	return v_name;
    END name;


    PROCEDURE check_nested_ind (
	tree_id in category_trees.tree_id%TYPE
    )
    IS
	v_negative number;
	v_order number;
	v_parent number;
    BEGIN
        select count(*) into v_negative from categories
	where tree_id = check_nested_ind.tree_id and (left_ind < 1 or right_ind < 1);

	if v_negative>0 then raise_application_error (-20001,'Negative Index not allowed!'); end if;

        select count(*) into v_order from categories
	where tree_id = check_nested_ind.tree_id
	and left_ind >= right_ind;
	
	if v_order>0 then raise_application_error (-20002,'Right Index must be greater than left Index!'); end if;

        select count(*) into v_parent
	from categories parent, categories child
		where parent.tree_id = check_nested_ind.tree_id
		and child.tree_id = parent.tree_id
		and (parent.left_ind >= child.left_ind or parent.right_ind <= child.right_ind)
		and child.parent_id = parent.category_id;

	if v_parent>0 then raise_application_error (-20003,'Child Index must be between parent Index!'); end if;
    END check_nested_ind;

end category_tree;
/
show errors
