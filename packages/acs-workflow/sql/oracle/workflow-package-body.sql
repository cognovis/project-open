--
-- acs-workflow/sql/workflow-package-head.sql
--
-- Creates the PL/SQL package that provides the API for defining and dropping
-- workflow cases.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--


create or replace package body workflow 
as
    
    function create_workflow (
        workflow_key 	in varchar2,
        pretty_name 	in varchar2, 
        pretty_plural 	in varchar2 default null,
        description 	in varchar2 default null,
        table_name 	in varchar2,
        id_column 	in varchar2 default 'case_id'
    ) 
    return varchar2
    is
	v_num_rows 	number;
        v_workflow_key 	varchar2(100);
    begin
	select count(*) into v_num_rows from user_tables where table_name = upper(create_workflow.table_name);
	if v_num_rows = 0 then
	    raise_application_error(-20000, 'The table '''||create_workflow.table_name||''' must be created before calling workflow.create_workflow.');
	end if;

        if substr(create_workflow.workflow_key, length(create_workflow.workflow_key) - 2, 3) != '_wf' then
            v_workflow_key := create_workflow.workflow_key||'_wf';
	else
	    v_workflow_key := create_workflow.workflow_key;
	end if;

        acs_object_type.create_type(
            object_type => v_workflow_key, 
            pretty_name => create_workflow.pretty_name, 
            pretty_plural => create_workflow.pretty_plural,
            supertype => 'workflow',
            table_name => create_workflow.table_name,
            id_column => create_workflow.id_column
        );

        insert into wf_workflows 
            (workflow_key, description) 
        values 
            (v_workflow_key, create_workflow.description);

        return v_workflow_key;
    end create_workflow;


    /* Note: The workflow-specific cases table must be dropped before calling this proc */
    procedure drop_workflow (
        workflow_key 	in varchar2
    )
    is
	v_table_name varchar2(100);
	v_num_rows number;
	cursor attribute_cur is
	    select attribute_id, attribute_name from acs_attributes where object_type = drop_workflow.workflow_key;
    begin
	select table_name into v_table_name 
 	from   acs_object_types
	where  object_type = drop_workflow.workflow_key;

	select decode(count(*),0,0,1) into v_num_rows 
	from   user_tables
	where  table_name = upper(v_table_name);

	if v_num_rows > 0 then
	    raise_application_error(-20000, 'The table '''||v_table_name||''' must be dropped before calling workflow.drop_workflow.');
	end if;

	select decode(count(*),0,0,1) into v_num_rows 
	from   wf_cases
	where  workflow_key = drop_workflow.workflow_key;

	if v_num_rows > 0 then
	    raise_application_error(-20000, 'You must delete all cases of workflow '''||drop_workflow.workflow_key||''' before dropping the workflow definition.');
	end if;

	/* Delete all the auxillary stuff */
        delete from wf_context_task_panels where workflow_key = drop_workflow.workflow_key;
	delete from wf_context_assignments where workflow_key = drop_workflow.workflow_key;
        delete from wf_context_role_info where workflow_key = drop_workflow.workflow_key;
	delete from wf_context_transition_info where workflow_key = drop_workflow.workflow_key;	
        delete from wf_context_workflow_info where workflow_key = drop_workflow.workflow_key;
	delete from wf_arcs where workflow_key = drop_workflow.workflow_key;
	delete from wf_places where workflow_key = drop_workflow.workflow_key;
	delete from wf_transition_role_assign_map where workflow_key = drop_workflow.workflow_key;
	delete from wf_transitions where workflow_key = drop_workflow.workflow_key;
        delete from wf_roles where workflow_key = drop_workflow.workflow_key;

	/* Drop all attributes */
	for attribute_rec in attribute_cur loop
	    /* there's no on delete cascade, so we have to manually delete all the values */
	    delete from acs_attribute_values where attribute_id = attribute_rec.attribute_id;

	    drop_attribute(
		workflow_key => drop_workflow.workflow_key,
		attribute_name => attribute_rec.attribute_name
	    );
	end loop;

	/* Delete the workflow */
	delete from wf_workflows where workflow_key = drop_workflow.workflow_key;
	
	acs_object_type.drop_type(
	    object_type => drop_workflow.workflow_key
	);
    end drop_workflow;


    procedure delete_cases (
	workflow_key 	in varchar2
    )
    is
	cursor workflow_cases is select case_id from wf_cases where workflow_key = delete_cases.workflow_key;
    begin
	for case_rec in workflow_cases loop
	    workflow_case.del(case_rec.case_id);
	end loop;
    end delete_cases;


    function create_attribute (
        workflow_key 	in varchar2,
        attribute_name 	in varchar2,
        datatype 	in varchar2,
        pretty_name 	in varchar2,
        pretty_plural 	in varchar2 default null,
        table_name 	in varchar2 default null,
        column_name 	in varchar2 default null,
        default_value 	in varchar2 default null,
        min_n_values 	in integer default 1,
        max_n_values 	in integer default 1,
        sort_order 	in integer default null,
        storage 	in varchar2 default 'generic'
    ) return acs_attributes.attribute_id%TYPE
    is
	v_attribute_id 	number;
    begin
	v_attribute_id := acs_attribute.create_attribute(
	    object_type => create_attribute.workflow_key,
	    attribute_name => create_attribute.attribute_name,
	    datatype => create_attribute.datatype,
	    pretty_name => create_attribute.pretty_name,
	    pretty_plural => create_attribute.pretty_plural,
	    table_name => create_attribute.table_name,
	    column_name => create_attribute.column_name,
	    default_value => create_attribute.default_value,
	    min_n_values => create_attribute.min_n_values,
	    max_n_values => create_attribute.max_n_values,
	    sort_order => create_attribute.sort_order,
	    storage => create_attribute.storage
        );
	
	return v_attribute_id;
    end create_attribute;


    procedure drop_attribute (
        workflow_key 	in varchar2,
	attribute_name 	in varchar2
    )
    is
        v_attribute_id 	number;
    begin
	select attribute_id into v_attribute_id
	from   acs_attributes
	where  object_type = drop_attribute.workflow_key
	and    attribute_name = drop_attribute.attribute_name;
	
	acs_attribute.drop_attribute(
	    object_type => drop_attribute.workflow_key,
	    attribute_name => drop_attribute.attribute_name
        );
    end drop_attribute;


    procedure add_place (
	workflow_key		in acs_object_types.object_type%TYPE,
	place_key		in wf_places.place_key%TYPE,
	place_name		in wf_places.place_name%TYPE,
	sort_order		in wf_places.sort_order%TYPE default null
    )
    is
      v_sort_order wf_places.sort_order%TYPE;
    begin
        if add_place.sort_order is null then
            select nvl(max(sort_order)+1, 1)
              into v_sort_order
              from wf_places
             where workflow_key = add_place.workflow_key;
        else
            v_sort_order := add_place.sort_order;
        end if;
	insert into wf_places (workflow_key, place_key, place_name, sort_order)
	values (add_place.workflow_key, add_place.place_key, add_place.place_name, v_sort_order);
    end add_place;

    procedure delete_place (
	workflow_key		in acs_object_types.object_type%TYPE,
	place_key		in wf_places.place_key%TYPE
    )
    is
    begin
	delete from wf_places
	where  workflow_key = delete_place.workflow_key	
	and    place_key = delete_place.place_key;
    end delete_place;

    procedure add_role (
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE,
        role_name               in wf_roles.role_name%TYPE,
        sort_order              in wf_roles.sort_order%TYPE default null
    )
    is
      v_sort_order wf_roles.sort_order%TYPE;
    begin
        if add_role.sort_order is null then
            select nvl(max(sort_order)+1, 1)
              into v_sort_order
              from wf_roles
	     where workflow_key = add_role.workflow_key;
        else
            v_sort_order := add_role.sort_order;
        end if;
        insert into wf_roles (
            workflow_key, role_key, role_name, sort_order
        ) values (
            add_role.workflow_key, add_role.role_key, add_role.role_name, v_sort_order
        );
    end add_role;

    procedure move_role_up(
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    )
    is
        v_this_sort_order wf_roles.sort_order%TYPE;
        v_prior_sort_order wf_roles.sort_order%TYPE; 
        cursor c_prior_sort_order is
	    select max(sort_order)
	      from wf_roles
	     where workflow_key = move_role_up.workflow_key
	       and sort_order < v_this_sort_order;
    begin
        select sort_order
          into v_this_sort_order
          from wf_roles
         where workflow_key = move_role_up.workflow_key
           and role_key = move_role_up.role_key;

        open c_prior_sort_order;
	fetch c_prior_sort_order into v_prior_sort_order;
        if c_prior_sort_order%NOTFOUND then
            /* already at top of sort order */
            return;
        end if;

        /* switch the sort orders around */
        update wf_roles
	   set sort_order = decode(role_key, move_role_up.role_key, v_prior_sort_order, v_this_sort_order)
         where workflow_key = move_role_up.workflow_key
           and sort_order in (v_this_sort_order, v_prior_sort_order);
    end move_role_up;

    procedure move_role_down(
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    )
    is
        v_this_sort_order wf_roles.sort_order%TYPE;
        v_next_sort_order wf_roles.sort_order%TYPE; 
        cursor c_next_sort_order is
	    select min(sort_order)
	      from wf_roles
	     where workflow_key = move_role_down.workflow_key
	       and sort_order > v_this_sort_order;
    begin
        select sort_order
          into v_this_sort_order
          from wf_roles
         where workflow_key = move_role_down.workflow_key
           and role_key = move_role_down.role_key;

        open c_next_sort_order;
	fetch c_next_sort_order into v_next_sort_order;
        if c_next_sort_order%NOTFOUND then
            /* already at bottom of sort order */
            return;
        end if;

        /* switch the sort orders around */
        update wf_roles
	   set sort_order = decode(role_key, move_role_down.role_key, v_next_sort_order, v_this_sort_order)
         where workflow_key = move_role_down.workflow_key
           and sort_order in (v_this_sort_order, v_next_sort_order);
    end move_role_down;

    procedure delete_role (
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    )
    is
    begin
        /* First, remove all references to this role from transitions */
        update wf_transitions
	   set role_key = null
         where workflow_key = delete_role.workflow_key
	   and role_key = delete_role.role_key;

        delete from wf_roles
        where  workflow_key = delete_role.workflow_key
        and    role_key = delete_role.role_key;
    end delete_role;

    procedure add_transition (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_transitions.transition_key%TYPE,
	transition_name		in wf_transitions.transition_name%TYPE,
        role_key                in wf_roles.role_key%TYPE default null,
	sort_order		in wf_transitions.sort_order%TYPE default null,
	trigger_type		in wf_transitions.trigger_type%TYPE default 'user'
    )
    is
        v_sort_order wf_transitions.sort_order%TYPE;
    begin
        if add_transition.sort_order is null then
            select nvl(max(sort_order)+1, 1)
              into v_sort_order
              from wf_transitions
             where workflow_key = add_transition.workflow_key;
        else
            v_sort_order := add_transition.sort_order;
        end if;
	insert into wf_transitions (
            workflow_key, 
            transition_key, 
            transition_name, 
            role_key,
            sort_order, 
            trigger_type
        ) values (
            add_transition.workflow_key, 
            add_transition.transition_key, 
            add_transition.transition_name,
            add_transition.role_key,
	    v_sort_order, 
            add_transition.trigger_type
        );
    end add_transition;

    procedure delete_transition (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_transitions.transition_key%TYPE
    )
    is
    begin
	delete from wf_transitions
	where  workflow_key = delete_transition.workflow_key
	and    transition_key = delete_transition.transition_key;
    end delete_transition;

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_arcs.transition_key%TYPE,
	place_key		in wf_arcs.place_key%TYPE,
	direction 		in wf_arcs.direction%TYPE,
	guard_callback	 	in wf_arcs.guard_callback%TYPE default null,
	guard_custom_arg	in wf_arcs.guard_custom_arg%TYPE default null,
	guard_description	in wf_arcs.guard_description%TYPE default null
    )
    is
    begin
	insert into wf_arcs (workflow_key, transition_key, place_key, direction,
	guard_callback, guard_custom_arg, guard_description)
	values (add_arc.workflow_key, add_arc.transition_key, add_arc.place_key, add_arc.direction,
	add_arc.guard_callback, add_arc.guard_custom_arg, add_arc.guard_description);
    end add_arc;

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	from_transition_key  	in wf_arcs.transition_key%TYPE,
	to_place_key		in wf_arcs.place_key%TYPE,
	guard_callback	 	in wf_arcs.guard_callback%TYPE default null,
	guard_custom_arg	in wf_arcs.guard_custom_arg%TYPE default null,
	guard_description	in wf_arcs.guard_description%TYPE default null
    )
    is
    begin
        add_arc(
            workflow_key => add_arc.workflow_key,
            transition_key => add_arc.from_transition_key,
            place_key => add_arc.to_place_key,
            direction => 'out',
            guard_callback => add_arc.guard_callback,
            guard_custom_arg => add_arc.guard_custom_arg,
            guard_description => add_arc.guard_description
        );
    end add_arc;

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	from_place_key		in wf_arcs.place_key%TYPE,
	to_transition_key  	in wf_arcs.transition_key%TYPE
    )
    is
    begin
        add_arc(
            workflow_key => add_arc.workflow_key,
            place_key => add_arc.from_place_key,
            transition_key => add_arc.to_transition_key,
            direction => 'in'
        );
    end add_arc;

    procedure delete_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_arcs.transition_key%TYPE,
	place_key		in wf_arcs.place_key%TYPE,
	direction 		in wf_arcs.direction%TYPE
    )
    is
    begin
	delete from wf_arcs
	where  workflow_key = delete_arc.workflow_key
	and    transition_key = delete_arc.transition_key
	and    place_key = delete_arc.place_key
	and    direction = delete_arc.direction;
    end delete_arc;

    procedure add_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_id            in acs_attributes.attribute_id%TYPE,
        sort_order              in wf_transition_attribute_map.sort_order%TYPE default null
    )
    is
        v_num_rows integer;
        v_sort_order wf_transition_attribute_map.sort_order%TYPE;
    begin
        select count(*)
          into v_num_rows
          from wf_transition_attribute_map
         where workflow_key = add_trans_attribute_map.workflow_key
	   and transition_key = add_trans_attribute_map.transition_key
	   and attribute_id = add_trans_attribute_map.attribute_id;

        if v_num_rows > 0 then
            return;
        end if;
        if add_trans_attribute_map.sort_order is null then
            select nvl(max(sort_order)+1, 1)
              into v_sort_order
              from wf_transition_attribute_map
             where workflow_key = add_trans_attribute_map.workflow_key
               and transition_key = add_trans_attribute_map.transition_key;
        else
            v_sort_order := add_trans_attribute_map.sort_order;
        end if;
        insert into wf_transition_attribute_map (
            workflow_key,
            transition_key,
            attribute_id,
            sort_order
        ) values (
            add_trans_attribute_map.workflow_key,
	    add_trans_attribute_map.transition_key,
            add_trans_attribute_map.attribute_id,
            v_sort_order
       );
    end add_trans_attribute_map;

    procedure add_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_name          in acs_attributes.attribute_name%TYPE,
        sort_order              in wf_transition_attribute_map.sort_order%TYPE default null
    )
    is
        v_attribute_id integer;
    begin
        select attribute_id
          into v_attribute_id
          from acs_attributes
         where object_type = add_trans_attribute_map.workflow_key
           and attribute_name = add_trans_attribute_map.attribute_name;

        add_trans_attribute_map(
            workflow_key => add_trans_attribute_map.workflow_key,
            transition_key => add_trans_attribute_map.transition_key,
            attribute_id => v_attribute_id,
            sort_order => add_trans_attribute_map.sort_order
        );
    end add_trans_attribute_map;

    procedure delete_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_id            in acs_attributes.attribute_id%TYPE
    )
    is
    begin
        delete
          from wf_transition_attribute_map
         where workflow_key = delete_trans_attribute_map.workflow_key
           and transition_key = delete_trans_attribute_map.transition_key
           and attribute_id = delete_trans_attribute_map.attribute_id;
    end delete_trans_attribute_map;

    procedure delete_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_name          in acs_attributes.attribute_id%TYPE
    )
    is
        v_attribute_id integer;
    begin
        select attribute_id
          into v_attribute_id
          from acs_attributes
         where object_type = delete_trans_attribute_map.workflow_key
           and attribute_name = delete_trans_attribute_map.attribute_name;

        delete
          from wf_transition_attribute_map
         where workflow_key = delete_trans_attribute_map.workflow_key
           and transition_key = delete_trans_attribute_map.transition_key
           and attribute_id = v_attribute_id;
    end delete_trans_attribute_map;

    procedure add_trans_role_assign_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        assign_role_key         in wf_roles.role_key%TYPE
    )
    is
      v_num_rows integer;
    begin
        select count(*)
          into v_num_rows
          from wf_transition_role_assign_map
	 where workflow_key = add_trans_role_assign_map.workflow_key
           and transition_key = add_trans_role_assign_map.transition_key
           and assign_role_key = add_trans_role_assign_map.assign_role_key;

        if v_num_rows = 0 then
	    insert into wf_transition_role_assign_map (
		workflow_key,
		transition_key,
		assign_role_key
	    ) values (
		add_trans_role_assign_map.workflow_key,
		add_trans_role_assign_map.transition_key,
		add_trans_role_assign_map.assign_role_key
	    );
        end if;
    end add_trans_role_assign_map;

    procedure delete_trans_role_assign_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        assign_role_key         in wf_roles.role_key%TYPE
    )
    is
    begin
        delete
          from wf_transition_role_assign_map
         where workflow_key = delete_trans_role_assign_map.workflow_key
           and transition_key = delete_trans_role_assign_map.transition_key
           and assign_role_key = delete_trans_role_assign_map.assign_role_key;
    end delete_trans_role_assign_map;


    function simple_p (
	workflow_key	in varchar2
    )
    return char
    is
	type t_place_table is table of wf_places.place_key%TYPE
	    index by binary_integer;
	type t_guard_table is table of wf_arcs.guard_callback%TYPE
	    index by binary_integer;
    
        previous_place_list 	t_place_table;
	target_place_list	t_place_table;
	guard_list	t_guard_table;
	row_count  	integer := 0;
	v_count     	integer;
	v_count2	integer;
	v_place_key	wf_places.place_key%TYPE;
	v_end_place	wf_places.place_key%TYPE;
	v_transition_key wf_transitions.transition_key%TYPE;

	cursor transition_targets is
	    select place_key,guard_callback,rownum
	    from   wf_arcs
	    where  workflow_key = simple_p.workflow_key
	    and    transition_key = v_transition_key
	    and    direction = 'out';

    begin
	/* Let's do some simple checks first */

	/* Places with more than one arc out */
	select count(*) into v_count
	from   wf_places p
	where  p.workflow_key = simple_p.workflow_key
	and    1 < (select count(*) 
		    from   wf_arcs a
	 	    where  a.workflow_key = p.workflow_key
		    and    a.place_key = p.place_key
		    and    direction = 'in');

	if v_count > 0 then
	    return 'f';
	end if;

	/* Transitions with more than one arc in */
	select count(*) into v_count
	from   wf_transitions t
	where  t.workflow_key = simple_p.workflow_key
	and    1 < (select count(*)
	            from   wf_arcs a
		    where  a.workflow_key = t.workflow_key
		    and    a.transition_key = t.transition_key
		    and    direction = 'in');

	if v_count > 0 then
	    return 'f';
	end if;

	/* Transitions with more than two arcs out */
	select count(*) into v_count
	from   wf_transitions t
	where  t.workflow_key = simple_p.workflow_key
	and    2 < (select count(*)
	            from   wf_arcs a
		    where  a.workflow_key = t.workflow_key
		    and    a.transition_key = t.transition_key
		    and    direction = 'out');

	if v_count > 0 then
	    return 'f';
	end if;

	/* Now we do the more complicated checks.
	 * We keep a list of visited places because I couldn't think
	 * of a nicer way that wasn't susceptable to infinite loops.
	 */


	v_place_key := 'start';
	v_end_place := 'end';

	loop
	    exit when v_place_key = v_end_place;

	    previous_place_list(row_count) := v_place_key;

	    select unique transition_key into v_transition_key
	    from   wf_arcs
	    where  workflow_key = simple_p.workflow_key
	    and    place_key = v_place_key
	    and    direction = 'in';

	    select count(*) into v_count
	    from wf_arcs
	    where workflow_key = simple_p.workflow_key
	    and   transition_key = v_transition_key
	    and   direction = 'out';

	    if v_count = 1 then
		select unique place_key into v_place_key
		from wf_arcs
		where workflow_key = simple_p.workflow_key
	        and   transition_key = v_transition_key
	        and   direction = 'out';

	    elsif v_count = 0 then
		/* deadend! */
		return 'f';

	    else
		/* better be two based on our earlier test */

    		for v_target in transition_targets loop
    		    target_place_list(v_target.rownum) := v_target.place_key;
    		    guard_list(v_target.rownum) := v_target.guard_callback;
    		end loop;
    
    		/* Check that the guard functions are the negation of each other 
    		 * by looking for the magic entry "#" (exactly once)
    		 */
    		if ((guard_list(1) != '#' and guard_list(2) != '#') or
    		    (guard_list(1) = '#' and guard_list(2) = '#')) then
    		    return 'f';
    		end if;
    
    		/* Check that exactly one of the targets is in the previous list */

    		v_count2 := 0;
    		for i in 0..row_count loop
    		    if target_place_list(1) = previous_place_list(i) then
    			v_count2 := v_count2 + 1;
    			v_place_key := target_place_list(2);
    		    end if;
    		    if target_place_list(2) = previous_place_list(i) then
    			v_count2 := v_count2 + 1;
    			v_place_key := target_place_list(1);
    		    end if;
    		end loop;

    		if v_count2 != 1 then
    		    return 'f';
    		end if;

	    end if;

	    row_count := row_count + 1;

	end loop;

	/* if we got here, it must be okay */
	return 't';

    end simple_p;

end workflow;
/
show errors
