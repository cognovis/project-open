-- upgrade-3.1.3.0.0-3.2.0.0.0.sql


-----------------------------------------------------------
-- Convert im_trans_task to an object
-----------------------------------------------------------

select acs_object_type__create_type (
        'im_trans_task',        -- object_type
        'Translation Task',     -- pretty_name
        'Translation Tasks',    -- pretty_plural
        'acs_object',           -- supertype
        'im_trans_tasks',       -- table_name
        'task_id',              -- id_column
        'im_trans_task',        -- package_name
        'f',                    -- abstract_p
        null,                   -- type_extension_table
        'im_trans_task__name'   -- name_method
);



create or replace function im_trans_task__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, integer, integer, integer, integer, integer
) returns integer as '
DECLARE
	p_task_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_project_id		alias for $7;
	p_task_type_id		alias for $8;
	p_task_status_id	alias for $9;
	p_source_language_id	alias for $10;
	p_target_language_id	alias for $11;
	p_task_uom_id		alias for $12;

	v_task_id	integer;
BEGIN
	v_task_id := acs_object__new (
		p_task_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_trans_tasks (
		task_id, project_id,
		task_type_id, task_status_id,
		source_language_id, target_language_id,
		task_uom_id
	) values (
		v_task_id, p_project_id,
		p_task_type_id, p_task_status_id,
		p_source_language_id, p_target_language_id,
		p_task_uom_id
	);

	return v_task_id;
end;' language 'plpgsql';



create or replace function im_trans_task__delete (integer) returns integer as '
DECLARE
	v_task_id	alias for $1;
BEGIN
	-- Erase all the priviledges
	delete from acs_permissions
	where object_id = v_task_id;

	-- Erase task_actions:
	delete from im_task_actions
	where task_id = v_task_id;
	
	-- Erase the im_trans_tasks item associated with the id
	delete from im_trans_tasks
	where task_id = v_task_id;

	PERFORM acs_object__delete(v_task_id);

	return 0;
end;' language 'plpgsql';


create or replace function im_trans_task__name (integer) returns varchar as '
DECLARE
	v_task_id    alias for $1;
	v_name    varchar;
BEGIN
	select  task_name
	into    v_name
	from    im_trans_tasks
	where   task_id = v_task_id;

	return v_name;
end;' language 'plpgsql';




-- Create entries for URL to allow editing TransTasks in
-- list pages with mixed object types
--
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','view','/intranet-translation/view?task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','edit','/intranet-translation/new?task_id=');




-----------------------------------------------------------
-- Prepare converting im_trans_task to object
-----------------------------------------------------------

alter table im_trans_quality_reports
drop constraint im_transq_task_fk;



-----------------------------------------------------------
-- Actually convert im_trans_task to object
-----------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
DECLARE
	row	RECORD;
	v_oid	integer;
BEGIN
    for row in
	select	*
	from	im_trans_tasks
	where	task_id not in (
	    select	object_id
	    from	acs_objects
	    where	object_type = ''im_trans_task''
	)
	order by task_id
    loop
	-- Create a new object for the task
	v_oid := acs_object__new (
		null,''im_trans_task'',now(),
		624,''0.0.0.0'',null
	);
	RAISE NOTICE ''im_trans_task: task_id=%, new oid=%'', row.task_id, v_oid;

	-- Update Task Actions
	update	im_task_actions
	set	task_id = v_oid
	where	task_id = row.task_id;

	-- Update Translation Quality
	update	im_trans_quality_reports
	set	task_id = v_oid
	where	task_id = row.task_id;

	-- Finally update the TransTask table itself
	update im_trans_tasks
	set task_id = v_oid
	where task_id = row.task_id;
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- No need anymore for the task sequence. Do this
-- to make sure that there are no further tasks
-- being generated somewhere in the system.
drop sequence im_trans_tasks_seq;


-- Prepare im_trans_tasks to become an object
-- alter table im_trans_tasks add object_id integer;

alter table im_trans_tasks
add constraint im_trans_task_id_fk
foreign key (task_id) references acs_objects;


-----------------------------------------------------------
-- Post-Process all tables that depend on im_trans_tasks
-----------------------------------------------------------


alter table im_trans_quality_reports
add constraint im_transq_task_fk
foreign key (task_id) references im_trans_tasks;


