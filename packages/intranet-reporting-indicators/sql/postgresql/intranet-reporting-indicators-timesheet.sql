-- indicators.sql
	
    


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
		''Average Timesheet Hours per Employee'',
		''hours_per_employee'',
		15110,
		15000,
		''select round(
(select sum(h.hours)
from    im_hours h
where   day between now()::date-60 and now()::date-60)
* 100 /
(select sum(coalesce(availability, 100)) as availability
from    im_employees e
where   e.employee_id in (select member_id from group_distinct_member_map where group_id = 463))
,1);
'',
		0,
		160,
		5
	);

	update im_indicators set
		indicator_section_id = 15215
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates the number of hours logged two month ago (now-60days - now-30days) divided by the number of full time employees (member of group employee multiplied with their ''''availability'''').''
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
		''Average Timesheet Hours per Project'',
		''avg_hours_per_project'',
		15110,
		15000,
		''select  round(avg(hours),1)
from    (
        select
                sum(h.hours) as hours,
                parent.project_id
        from
                im_projects parent,
                im_projects p,
                im_hours h
        where
                parent.parent_id is null and
                parent.end_date > now() and
                p.project_id = h.project_id and
                p.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
        group by
                parent.project_id
        ) p
;'',
		0,
		30,
		5
	);

	update im_indicators set
		indicator_section_id = 15215
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Shows the average number of hours logged per project, for all projects not yet finished (the project''''s end date in the future)''
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
		''Productive Hours'',
		''productive_hours'',
		15110,
		15000,
		''select  round(
        (select sum(h.hours)
        from    im_hours h,
                im_projects p,
                im_companies c
        where   day > now()::date-30 and
                h.project_id = p.project_id and
                p.company_id = c.company_id and
                c.company_path != ''''internal''''
        )
        /
        (select         sum(h.hours)
        from    im_hours h
        where   day > now()::date-30
        )
        * 100
,1);
'',
		0,
		100,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates how many percent of timesheet hours are logged on customer projects vs. ''''internal'''' projects.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=10000, indicator_low_warn=20000, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'revenues');

