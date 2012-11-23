-- upgrade-4.0.3.3.2-4.0.3.3.3.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-4.0.3.3.2-4.0.3.3.3.sql','') from dual;


create or replace function im_projects_tsearch ()
returns trigger as '
declare
	v_string	varchar;
	v_string2	varchar;
	v_object_type	varchar;
begin
	select	coalesce(project_name, '''') || '' '' ||
		coalesce(project_nr, '''') || '' '' ||
		coalesce(project_path, '''') || '' '' ||
		coalesce(description, '''') || '' '' ||
		coalesce(note, ''''),
		o.object_type
	into	v_string, v_object_type
	from	im_projects p,
		acs_objects o
	where	p.project_id = new.project_id and
		p.project_id = o.object_id;

	-- Skip if this is a ticket. There is a special trigger for tickets.
	-- im_timesheet_task is still handled as a project.
	IF ''im_ticket'' = v_object_type THEN return new; END IF;

	v_string2 := '''';
	IF column_exists(''im_projects'', ''company_project_nr'') THEN
		select	coalesce(company_project_nr, '''')
		into	v_string2
		from	im_projects
		where	project_id = new.project_id;
		v_string := v_string || '' '' || v_string2;
	END IF;

	perform im_search_update(new.project_id, ''im_project'', new.project_id, v_string);

	return new;
end;' language 'plpgsql';


create or replace function im_projects_tsearch_too_slow () 
returns trigger as '
declare
	v_string	varchar;	v_string2	varchar;
	v_select	varchar;	v_value		varchar;
	v_sql		varchar;	row		record;		v_rec	record;
begin
	select 	coalesce(project_name, '''') || '' '' || coalesce(project_nr, '''') || '' '' ||
		coalesce(project_path, '''') || '' '' || coalesce(description, '''') || '' '' ||
		coalesce(note, '''')
	into	v_string
	from	im_projects where project_id = new.project_id;

	v_string2 := '''';
	if column_exists(''im_projects'', ''company_project_nr'') then
		select 	coalesce(company_project_nr, '''')
		into	v_string2
		from	im_projects where project_id = new.project_id;
		v_string := v_string || '' '' || v_string2;
	end if;

	-- Concat the indexable DynField fields...
	v_sql := '' '''' '''' '';
	FOR row IN
		select	w.deref_plpgsql_function, 
			aa.attribute_name
		from	im_dynfield_widgets w,
			im_dynfield_attributes a,
			acs_attributes aa
		where	a.widget_name = w.widget_name and
			a.acs_attribute_id = aa.attribute_id and
			aa.object_type = ''im_project'' and
			a.include_in_search_p = ''t''
	LOOP
v_sql := v_sql||'' || '''' '''' ||coalesce(''||row.deref_plpgsql_function||''(''||row.attribute_name||''),0::varchar) '';
	END LOOP;

	v_sql := ''select '' || v_sql || '' as value from im_projects where project_id = '' || new.project_id;
	RAISE NOTICE ''im_projects_tsearch: sql=% '', v_sql;
	
	-- Workaround - execute doesnt work yet with select_into, so we execute as part of a loop..
	FOR v_rec IN EXECUTE v_sql LOOP v_string := v_string || '' '' || v_rec.value; END LOOP;

	PERFORM im_search_update(new.project_id, ''im_project'', new.project_id, v_string);
	return new;
end;' language 'plpgsql';

