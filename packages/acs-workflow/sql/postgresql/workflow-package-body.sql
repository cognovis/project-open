-- /packages/acs-workflow/sql/postgresql/workflow-package-body.sql

-- create or replace package body workflow 
-- function create_workflow
create or replace function workflow__create_workflow (varchar,varchar,varchar,varchar,varchar,varchar)
returns varchar as '
declare
	create_workflow__workflow_key		alias for $1;	
	create_workflow__pretty_name		alias for $2;	
	create_workflow__pretty_plural		alias for $3;	-- default null	
	create_workflow__description		alias for $4;	-- default null
	create_workflow__table_name		alias for $5;	
	create_workflow__id_column		alias for $6;	-- default ''case_id''
	v_num_rows				integer;
	v_workflow_key				varchar;
begin
	select count(*) into v_num_rows from pg_class
	where relname = lower(create_workflow__table_name);

	if v_num_rows = 0 then
		raise EXCEPTION ''-20000: The table "%"must be created before calling workflow.create_workflow.'', create_workflow__table_name;
	end if;

	if substr(create_workflow__workflow_key, length(create_workflow__workflow_key) - 2, 3) != ''_wf'' then
		v_workflow_key := create_workflow__workflow_key || ''_wf'';
	else
		v_workflow_key := create_workflow__workflow_key;
	end if;

	PERFORM acs_object_type__create_type (
		v_workflow_key, 
		create_workflow__pretty_name, 
		create_workflow__pretty_plural,
		''workflow'',
		create_workflow__table_name,
		create_workflow__id_column,
		null,
		''f'',
		null,
		null
	);

	insert into wf_workflows (
		workflow_key, description
	) values (
		v_workflow_key, create_workflow__description
	);

	return v_workflow_key;
	
end;' language 'plpgsql';


/* Note: The workflow-specific cases table must be dropped before calling this proc */
create or replace function workflow__drop_workflow (varchar)
returns integer as '
declare
	drop_workflow__workflow_key		alias for $1;	
	v_table_name				varchar;	
	v_num_rows				integer;	
	attribute_rec				record;
begin
	select table_name into v_table_name from acs_object_types
	where	object_type = drop_workflow__workflow_key;

	select case when count(*) = 0 then 0 else 1 end into v_num_rows from pg_class
	where	relname = lower(v_table_name);

	if v_num_rows > 0 then
		raise EXCEPTION ''-20000: The table "%" must be dropped before calling workflow__drop_workflow.'', v_table_name;
	end if;

	select case when count(*) = 0 then 0 else 1 end into v_num_rows from wf_cases
	where	workflow_key = drop_workflow__workflow_key;

	if v_num_rows > 0 then
		raise EXCEPTION ''-20000: You must delete all cases of workflow "%" before dropping the workflow definition.'', drop_workflow__workflow_key;
	end if;

	/* Delete all the auxillary stuff */
	delete from wf_context_task_panels where workflow_key = drop_workflow__workflow_key;
	delete from wf_context_assignments where workflow_key = drop_workflow__workflow_key;
	delete from wf_context_role_info where workflow_key = drop_workflow__workflow_key; 
	delete from wf_context_transition_info where workflow_key = drop_workflow__workflow_key; 
	delete from wf_context_workflow_info where workflow_key = drop_workflow__workflow_key;
	delete from wf_arcs where workflow_key = drop_workflow__workflow_key;
	delete from wf_places where workflow_key = drop_workflow__workflow_key;
	delete from wf_transition_role_assign_map where workflow_key = drop_workflow__workflow_key;
	delete from wf_transitions where workflow_key = drop_workflow__workflow_key;
	delete from wf_roles where workflow_key = drop_workflow__workflow_key;

	/* Drop all attributes */
	for attribute_rec in 
		select attribute_id, attribute_name 
		from acs_attributes 
		where object_type = drop_workflow__workflow_key
	LOOP
		/* there is no on delete cascade, so we have to manually 
		* delete all the values 
		*/

		delete from acs_attribute_values where attribute_id = attribute_rec.attribute_id;

		PERFORM workflow__drop_attribute (
			drop_workflow__workflow_key,
			attribute_rec.attribute_name
		);
	end loop;

	/* Delete the workflow */
	delete from wf_workflows where workflow_key = drop_workflow__workflow_key;
	
	PERFORM acs_object_type__drop_type (
		drop_workflow__workflow_key,
		''f''
	);

	return 0; 
end;' language 'plpgsql';


-- procedure delete_cases
create or replace function workflow__delete_cases (varchar)
returns integer as '
declare
	delete_cases__workflow_key		alias for $1; 
	case_rec				record; 
begin
	for case_rec in 
		select case_id 
		from wf_cases 
		where workflow_key = delete_cases__workflow_key
	LOOP
		PERFORM workflow_case__delete(case_rec.case_id);
	end loop;

	return 0; 
end;' language 'plpgsql';


-- function create_attribute
create or replace function workflow__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,varchar)
returns integer as '
declare
	create_attribute__workflow_key		alias for $1;	
	create_attribute__attribute_name	alias for $2;	
	create_attribute__datatype		alias for $3;	
	create_attribute__pretty_name		alias for $4;	
	create_attribute__pretty_plural		alias for $5;	-- default null	
	create_attribute__table_name		alias for $6;	-- default null
	create_attribute__column_name		alias for $7;	-- default null
	create_attribute__default_value		alias for $8;	-- default null
	create_attribute__min_n_values		alias for $9;	-- default 1
	create_attribute__max_n_values		alias for $10; -- default 1
	create_attribute__sort_order		alias for $11; -- default null
	create_attribute__storage		alias for $12; -- default ''generic''
	v_attribute_id				integer;	
begin
	v_attribute_id := acs_attribute__create_attribute(
		create_attribute__workflow_key,
		create_attribute__attribute_name,
		create_attribute__datatype,
		create_attribute__pretty_name,
		create_attribute__pretty_plural,
		create_attribute__table_name,
		create_attribute__column_name,
		create_attribute__default_value,
		create_attribute__min_n_values,
		create_attribute__max_n_values,
		create_attribute__sort_order,
		create_attribute__storage,
		''f''
	);

	return v_attribute_id;
	
end;' language 'plpgsql';


-- procedure drop_attribute
create or replace function workflow__drop_attribute (varchar,varchar)
returns integer as '
declare
	drop_attribute__workflow_key	alias for $1;	
	drop_attribute__attribute_name	alias for $2;	
	v_attribute_id			integer;	
begin
	select attribute_id into v_attribute_id
	from	acs_attributes
	where	object_type = drop_attribute__workflow_key
		and	attribute_name = drop_attribute__attribute_name;

	PERFORM acs_attribute__drop_attribute (
		drop_attribute__workflow_key,
		drop_attribute__attribute_name
	);

	return 0; 
end;' language 'plpgsql';


-- procedure add_place
create or replace function workflow__add_place (varchar,varchar,varchar,integer)
returns integer as '
declare
	add_place__workflow_key		alias for $1;	
	add_place__place_key		alias for $2;	
	add_place__place_name		alias for $3;	
	add_place__sort_order		alias for $4; 
	v_sort_order			integer; 
begin
	if add_place__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_places
		where workflow_key = add_place__workflow_key;
	else
		v_sort_order := add_place__sort_order;
	end if;
	insert into wf_places (workflow_key, place_key, place_name, sort_order)
	values (add_place__workflow_key, add_place__place_key,add_place__place_name, add_place__sort_order);

	return 0; 
end;' language 'plpgsql';


-- procedure delete_place
create or replace function workflow__delete_place (varchar,varchar)
returns integer as '
declare
	delete_place__workflow_key	alias for $1;	
	delete_place__place_key		alias for $2;	
begin
	delete from wf_places
	where	workflow_key = delete_place__workflow_key 
	and	place_key = delete_place__place_key;

	return 0; 
end;' language 'plpgsql';


-- procedure add_role
create or replace function workflow__add_role (varchar,varchar,varchar,integer)
returns integer as '
declare
	add_role__workflow_key		alias for $1;
	add_role__role_key		alias for $2;
	add_role__role_name		alias for $3;
	add_role__sort_order		alias for $4;
	v_sort_order			integer;
begin
	if add_role__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_roles
		where workflow_key = add_role__workflow_key;
	else
		v_sort_order := add_role__sort_order;
	end if;
	insert into wf_roles (
		workflow_key, role_key, role_name, sort_order
	) values (
		add_role__workflow_key, add_role__role_key, add_role__role_name, v_sort_order
	);
	return 0; 
end;' language 'plpgsql';


-- procedure move_role_up
create or replace function workflow__move_role_up (varchar,varchar)
returns integer as '
declare
	move_role_up__workflow_key		alias for $1;
	move_role_up__role_key			alias for $2;
	v_this_sort_order			integer;
	v_prior_sort_order			integer;
begin
	select sort_order into v_this_sort_order
	from	wf_roles
	where	workflow_key = move_role_up__workflow_key
		and role_key = move_role_up__role_key;

	select max(sort_order) into v_prior_sort_order
	from wf_roles
	where workflow_key = move_role_up__workflow_key
		and sort_order < v_this_sort_order;

	if not found then
		/* already at top of sort order */
		return 0;
	end if;

	/* switch the sort orders around */
	update wf_roles
	set sort_order = (case when role_key=move_role_up__role_key then v_prior_sort_order else v_this_sort_order end)
	where workflow_key = move_role_up__workflow_key
		and sort_order in (v_this_sort_order, v_prior_sort_order);

	return 0;
end;' language 'plpgsql';


-- procedure move_role_down
create or replace function workflow__move_role_down (varchar,varchar)
returns integer as '
declare
	move_role_down__workflow_key		alias for $1;
	move_role_down__role_key		alias for $2;
	v_this_sort_order			integer;
	v_next_sort_order			integer;
begin
	select sort_order
		into v_this_sort_order
		from wf_roles
	where workflow_key = move_role_down__workflow_key
		and role_key = move_role_down__role_key;

	select min(sort_order)
	into v_next_sort_order
	from wf_roles
	where workflow_key = move_role_down__workflow_key
	and sort_order > v_this_sort_order;

	if not found then
		/* already at bottom of sort order */
		return 0;
	end if;

	/* switch the sort orders around */
	update wf_roles
	set sort_order = (case when role_key=move_role_down__role_key then v_next_sort_order else v_this_sort_order end)
	where workflow_key = move_role_down__workflow_key
		and sort_order in (v_this_sort_order, v_next_sort_order);

	return 0;
end;' language 'plpgsql';


-- procedure delete_role
create or replace function workflow__delete_role (varchar,varchar)
returns integer as '
declare
	delete_role__workflow_key		alias for $1;
	delete_role__role_key			alias for $2;
begin
	/* First, remove all references to this role from transitions */
	update wf_transitions
	set role_key = null
	where workflow_key = delete_role__workflow_key
	and role_key = delete_role__role_key;

	delete from wf_roles
	where	workflow_key = delete_role__workflow_key
	and	role_key = delete_role__role_key;

	return 0;
end;' language 'plpgsql';


-- procedure add_transition
create or replace function workflow__add_transition (varchar,varchar,varchar,varchar,integer,varchar)
returns integer as '
declare
	add_transition__workflow_key		alias for $1;	
	add_transition__transition_key		alias for $2;	
	add_transition__transition_name		alias for $3;	
	add_transition__role_key		alias for $4;
	add_transition__sort_order		alias for $5;	
	add_transition__trigger_type		alias for $6;	-- default ''user''
	v_sort_order				integer;
begin
	if add_transition__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_transitions
		where workflow_key = add_transition__workflow_key;
	else
		v_sort_order := add_transition__sort_order;
	end if;
	insert into wf_transitions (
		workflow_key, 
		transition_key, 
		transition_name, 
		role_key,
		sort_order, 
		trigger_type
	) values (
		add_transition__workflow_key, 
		add_transition__transition_key, 
		add_transition__transition_name,
		add_transition__role_key,
		v_sort_order, 
		add_transition__trigger_type
	);

	return 0; 
end;' language 'plpgsql';


-- procedure delete_transition
create or replace function workflow__delete_transition (varchar,varchar)
returns integer as '
declare
	delete_transition__workflow_key	alias for $1;	
	delete_transition__transition_key	alias for $2;	
begin
	delete from wf_transitions
	where	workflow_key = delete_transition__workflow_key
	and	transition_key = delete_transition__transition_key;

	return 0; 
end;' language 'plpgsql';


-- procedure add_arc
create or replace function workflow__add_arc (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
	add_arc__workflow_key		alias for $1;	
	add_arc__transition_key		alias for $2;	
	add_arc__place_key		alias for $3;	
	add_arc__direction		alias for $4;	
	add_arc__guard_callback		alias for $5;	-- default null	
	add_arc__guard_custom_arg	alias for $6;	-- default null
	add_arc__guard_description	alias for $7;	-- default null
begin
	insert into wf_arcs (workflow_key, transition_key, place_key, direction,
	guard_callback, guard_custom_arg, guard_description)
	values (add_arc__workflow_key, add_arc__transition_key, add_arc__place_key, add_arc__direction,
	add_arc__guard_callback, add_arc__guard_custom_arg, add_arc__guard_description);

	return 0; 
end;' language 'plpgsql';


-- procedure add_arc
create or replace function workflow__add_arc (varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
	add_arc__workflow_key		alias for $1;
	add_arc__from_transition_key	alias for $2;
	add_arc__to_place_key		alias for $3;
	add_arc__guard_callback		alias for $4;
	add_arc__guard_custom_arg	alias for $5;
	add_arc__guard_description	alias for $6;
begin
	perform workflow__add_arc (
		add_arc__workflow_key,
		add_arc__from_transition_key,
		add_arc__to_place_key,
		''out'',
		add_arc__guard_callback,
		add_arc__guard_custom_arg,
		add_arc__guard_description
	);

	return 0;
end;' language 'plpgsql';


-- procedure add_arc
create or replace function workflow__add_arc (varchar,varchar,varchar)
returns integer as '
declare
	add_arc__workflow_key		alias for $1;
	add_arc__from_place_key		alias for $2;
	add_arc__to_transition_key	alias for $3;
begin
	perform workflow__add_arc(
		add_arc__workflow_key,
		add_arc__to_transition_key,
		add_arc__from_place_key,
		''in'',
		null,
		null,
		null
	);	

	return 0;
end;' language 'plpgsql';


-- procedure delete_arc
create or replace function workflow__delete_arc (varchar,varchar,varchar,varchar)
returns integer as '
declare
	delete_arc__workflow_key	alias for $1;	
	delete_arc__transition_key	alias for $2;	
	delete_arc__place_key		alias for $3;	
	delete_arc__direction		alias for $4;	
begin
	delete from wf_arcs
	where	workflow_key = delete_arc__workflow_key
	and	transition_key = delete_arc__transition_key
	and	place_key = delete_arc__place_key
	and	direction = delete_arc__direction;

	return 0; 
end;' language 'plpgsql';



-- procedure add_trans_attribute_map
create or replace function workflow__add_trans_attribute_map (varchar,varchar,integer,integer)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2; 
	p_attribute_id			alias for $3;
	p_sort_order			alias for $4;
	v_num_rows			integer;
	v_sort_order			integer;
begin
	select count(*)
		into v_num_rows
		from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = p_attribute_id;

	if v_num_rows > 0 then
		return 0;
	end if;
	if p_sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_transition_attribute_map
		where workflow_key = p_workflow_key
		and transition_key = p_transition_key;
	else
		v_sort_order := p_sort_order;
	end if;
	insert into wf_transition_attribute_map (
		workflow_key,
		transition_key,
		attribute_id,
		sort_order
	) values (
		p_workflow_key,
		p_transition_key,
		p_attribute_id,
		v_sort_order
	);
	return 0;
end;' language 'plpgsql';



-- procedure add_trans_attribute_map
create or replace function workflow__add_trans_attribute_map (varchar,varchar,varchar,integer)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2;
	p_attribute_name		alias for $3;
	p_sort_order			alias for $4;
	v_attribute_id			integer;
begin
	select attribute_id
		into v_attribute_id
		from acs_attributes
	where object_type = p_workflow_key
		and attribute_name = p_attribute_name;

	perform workflow__add_trans_attribute_map (
		p_workflow_key,
		p_transition_key,
		v_attribute_id,
		p_sort_order
	);

	return 0;

end;' language 'plpgsql';


-- procedure delete_trans_attribute_map
create or replace function workflow__delete_trans_attribute_map (varchar,varchar,integer)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2;
	p_attribute_id			alias for $3;
begin
	delete
		from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = p_attribute_id;

	return 0;
end;' language 'plpgsql';

-- procedure delete_trans_attribute_map
create or replace function workflow__delete_trans_attribute_map (varchar,varchar,varchar)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2;
	p_attribute_name		alias for $3;
	v_attribute_id			integer;
begin
	select attribute_id
		into v_attribute_id
		from acs_attributes
	where object_type = p_workflow_key
		and attribute_name = p_attribute_name;

	delete from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = v_attribute_id;

	return 0;
end;' language 'plpgsql';


-- procedure add_trans_role_assign_map
create or replace function workflow__add_trans_role_assign_map (varchar,varchar,varchar)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2;
	p_assign_role_key		alias for $3;
	v_num_rows			integer;
begin
	select count(*)
		into v_num_rows
		from wf_transition_role_assign_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and assign_role_key = p_assign_role_key;

	if v_num_rows = 0 then
		insert into wf_transition_role_assign_map (
		workflow_key,
		transition_key,
		assign_role_key
		) values (
		p_workflow_key,
		p_transition_key,
		p_assign_role_key
		);
	end if;

	return 0;
end;' language 'plpgsql';

-- procedure delete_trans_role_assign_map
create or replace function workflow__delete_trans_role_assign_map (varchar,varchar,varchar)
returns integer as '
declare
	p_workflow_key			alias for $1;
	p_transition_key		alias for $2;
	p_assign_role_key		alias for $3;
begin
	delete from wf_transition_role_assign_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and assign_role_key = p_assign_role_key;

	return 0;
end;' language 'plpgsql';



create sequence workflow_session_id;

create table previous_place_list (
		session_id	integer,
		rcnt		integer,
		constraint previous_place_list_pk
		primary key (session_id, rcnt),
		ky		varchar(100)
);

create table target_place_list (
		session_id	integer,
		rcnt		integer,
		constraint target_place_list_pk
		primary key (session_id, rcnt),
		ky		varchar(100)
);

create table guard_list (
		session_id	integer,
		rcnt		integer,
		constraint quard_list_pk 
		primary key (session_id, rcnt),
		ky		varchar(100)
);

create or replace function workflow__simple_p (varchar)
returns boolean as '
declare
	simple_p__workflow_key		alias for $1;	
	v_session_id			integer;
	retval				boolean;
begin
	v_session_id := nextval(''workflow_session_id'');
	retval := __workflow__simple_p(simple_p__workflow_key, v_session_id);

	delete from previous_place_list where session_id = v_session_id;
	delete from target_place_list where session_id = v_session_id;
	delete from guard_list where session_id = v_session_id;

	return retval;

end;' language 'plpgsql';

-- function simple_p

create or replace function __workflow__simple_p (varchar,integer)
returns boolean as '
declare
	simple_p__workflow_key		alias for $1;	
	v_session_id			alias for $2;

	-- previous_place_list		t_place_table; 
	-- target_place_list		t_place_table; 
	-- guard_list			t_guard_table; 
	guard_list_1			varchar;
	guard_list_2			varchar;
	target_place_list_1		varchar;
	target_place_list_2		varchar;
	previous_place_list_i		varchar;
	v_row_count			integer default 0;	
	v_count				integer;	
	v_count2			integer;	
	v_place_key			wf_places.place_key%TYPE;
	v_end_place			wf_places.place_key%TYPE;
	v_transition_key		wf_transitions.transition_key%TYPE;
	v_rownum			integer;
	v_target			record;
begin

	/* Let us do some simple checks first */

	/* Places with more than one arc out */
	select count(*) into v_count
	from	wf_places p
	where	p.workflow_key = simple_p__workflow_key
	and	1 < (select count(*) 
			from	wf_arcs a
			where	a.workflow_key = p.workflow_key
			and	a.place_key = p.place_key
			and	direction = ''in'');
	raise notice ''query 1'';
	if v_count > 0 then
		return ''f'';
	end if;

	/* Transitions with more than one arc in */
	select count(*) into v_count
	from	wf_transitions t
	where	t.workflow_key = simple_p__workflow_key
	and	1 < (select count(*)
			from	wf_arcs a
			where	a.workflow_key = t.workflow_key
			and	a.transition_key = t.transition_key
			and	direction = ''in'');

	raise notice ''query 2'';
	if v_count > 0 then
		return ''f'';
	end if;

	/* Transitions with more than two arcs out */
	select count(*) into v_count
	from	wf_transitions t
	where	t.workflow_key = simple_p__workflow_key
	and	2 < (select count(*)
			from	wf_arcs a
			where	a.workflow_key = t.workflow_key
			and	a.transition_key = t.transition_key
			and	direction = ''out'');

	raise notice ''query 3'';
	if v_count > 0 then
		return ''f'';
	end if;

	/* Now we do the more complicated checks.
	* We keep a list of visited places because I could not think
	* of a nicer way that was not susceptable to infinite loops.
	*/


	v_place_key := ''start'';
	v_end_place := ''end'';

	loop
		exit when v_place_key = v_end_place;

		-- previous_place_list(v_row_count) := v_place_key;
		insert into previous_place_list 
		(session_id,rcnt,ky) 
		values 
		(v_session_id,v_row_count,v_place_key);
	raise notice ''query 4'';

		select distinct transition_key into v_transition_key
		from	wf_arcs
		where	workflow_key = simple_p__workflow_key
		and	place_key = v_place_key
		and	direction = ''in'';
	raise notice ''query 5'';

		select count(*) into v_count
		from wf_arcs
		where workflow_key = simple_p__workflow_key
		and	transition_key = v_transition_key
		and	direction = ''out'';
	raise notice ''query 6'';

		if v_count = 1 then
			select distinct place_key into v_place_key
			from wf_arcs
			where workflow_key = simple_p__workflow_key
			and	transition_key = v_transition_key
			and	direction = ''out'';
	raise notice ''query 7'';

		else if v_count = 0 then
			/* deadend! */
			return ''f'';

		else
			/* better be two based on our earlier test */

			v_rownum := 1;
			for v_target in 
				select place_key,guard_callback
				from	wf_arcs
				where	workflow_key = simple_p__workflow_key
				and	transition_key = v_transition_key
				and	direction = ''out''
			LOOP
			-- target_place_list(v_target.rownum) := v_target.place_key;
	raise notice ''query 8'';
			insert into target_place_list (session_id,rcnt,ky) 
			values (v_session_id,v_rownum,v_target.place_key);
	raise notice ''query 9'';

			-- guard_list(v_target.rownum) := v_target.guard_callback; 
			insert into guard_list (session_id,rcnt,ky) 
			values (v_session_id,v_rownum,v_target.guard_callback);
			v_rownum := v_rownum + 1;
	raise notice ''query 10'';
			end loop;
	
			/* Check that the guard functions are the negation of each other 
			* by looking for the magic entry "#" (exactly once)
			*/
			select ky into guard_list_1 from guard_list 
			where session_id = v_session_id and rcnt = 1;
	raise notice ''query 11'';

			select ky into guard_list_2 from guard_list 
			where session_id = v_session_id and rcnt = 2;
	raise notice ''query 12'';

			if ((guard_list_1 != ''#'' and guard_list_2 != ''#'') or
			(guard_list_1 = ''#'' and guard_list_2 = ''#'')) then
			return ''f'';
			end if;
	
			/* Check that exactly one of the targets is in the previous list */

			v_count2 := 0;
			select ky into target_place_list_1 from target_place_list 
			where session_id = v_session_id and rcnt = 1;
	raise notice ''query 13'';

			select ky into target_place_list_2 from target_place_list 
			where session_id = v_session_id and rcnt = 2;			
	raise notice ''query 14'';

			for i in 0..v_row_count LOOP
				select ky into previous_place_list_i 
				from previous_place_list where session_id = v_session_id 
				and rcnt = i;
			if target_place_list_1 = previous_place_list_i then
				v_count2 := v_count2 + 1;
				v_place_key := target_place_list_2;
			end if;
			if target_place_list_2 = previous_place_list_i then
				v_count2 := v_count2 + 1;
				v_place_key := target_place_list_1;
			end if;
			end loop;
	raise notice ''query 15'';

			if v_count2 != 1 then
			return ''f'';
			end if;

		end if; end if;

		v_row_count := v_row_count + 1;

	end loop;

	/* if we got here, it must be okay */
	return ''t'';

	
end;' language 'plpgsql';


