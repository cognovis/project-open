-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.4.0.2.0-3.4.0.3.0.sql','');



create or replace function inline_0 ()
returns integer as '
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_gantt_projects'';
	if v_count > 0 then return 0; end if;

	create table im_gantt_projects (
		project_id		integer
					primary key,
		xml_elements		varchar(1000)
					not null
	);

	alter table only im_gantt_projects
		add constraint im_gantt_projects_project_id_fk 
		foreign key (project_id) references im_projects(project_id);

	PERFORM acs_object_type__create_type (
		''im_gantt_project'',	-- object_type
		''GanttProject'',	-- pretty_name
		''GanttProjects'',	-- pretty_plural
		''im_project'',		-- supertype
		''im_gantt_projects'',	-- table_name
		''project_id'',		-- id_column
		''im_gantt_project'',	-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		''im_project__name''		-- name_method
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_gantt_persons'';
	if v_count > 0 then return 0; end if;

	create table im_gantt_persons (
		person_id		integer
					primary key,
		xml_elements		varchar(1000)
					not null
	);

	alter table only im_gantt_persons
		add constraint im_gantt_persons_person_id_fk 
		foreign key (person_id) references persons(person_id);

	PERFORM acs_object_type__create_type (
		''im_gantt_person'',		-- object_type
		''GanttPerson'',		-- pretty_name
		''GanttPersons'',		-- pretty_plural
		''person'', 			-- supertype
		''im_gantt_persons'',		-- table_name
		''person_id'',			-- id_column
		''im_gantt_person'',		-- package_name
		''f'',				-- abstract_p
		null,				-- type_extension_table
		''im_person__name''		-- name_method
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

