-- upgrade-3.4.0.7.0-3.4.0.7.1.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.4.0.7.0-3.4.0.7.1.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_gantt_project'' and table_name = ''im_gantt_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	-- make sure im_gantt_project object type exists...
	select count(*) into v_count from acs_object_types
	where object_type = ''im_gantt_project'';
	IF v_count = 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_gantt_project'', ''im_gantt_projects'', ''project_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_gantt_project'' and table_name = ''im_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;

	-- make sure im_gantt_project object type exists...
	select count(*) into v_count from acs_object_types
	where object_type = ''im_gantt_project'';
	IF v_count = 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_gantt_project'', ''im_projects'', ''project_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



delete from im_biz_object_urls where object_type = 'im_gantt_project';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','edit','/intranet/projects/new?project_id=');

