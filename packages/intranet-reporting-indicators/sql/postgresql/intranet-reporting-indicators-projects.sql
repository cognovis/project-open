-- indicators-projects.sql
	


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''New projects per month'',
		''new_project_per_month'',
		15110,
		15000,
''select count(*) from im_projects where start_date > now()::date-30 and start_date <= now()::date'',
		0,
		300,
		5
	);

	update im_indicators set indicator_section_id = 15205
	where indicator_id = v_id;

	update im_reports set report_description = 
''Main projects (no subprojects) started in the last 30 days.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Late Projects'',
		''late_projects'',
		15110,
		15000,
		''select count(*)
from im_projects p
where p.parent_id is null and
p.project_status_id in (select * from im_sub_categories(76)) and
p.end_date < now()'',
		0,
		3,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of open projects with an end date earlier then now.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    
    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Open Projects'',
		''open_projects'',
		15110,
		15000,
		''select count(*)
from im_projects
where parent_id is null and
project_status_id = 76'',
		0,
		50,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of main projects with status ''''open''''.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''Average Project Duration'',
		''project_duration'',
		15110,
		15000,
		''
select  round(avg(end_date::date - start_date::date),1) as duration
from    im_projects
where   project_status_id in (select * from im_sub_categories(76))
;'',
		0,
		30,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates the average duration (end_date - start_date) in days of all currently open projects.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''External Costs'',
		''external_costs'',



-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=10, indicator_low_warn=20, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'new_project_per_month');
