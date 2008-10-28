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
		''New projects per month'',
		''new_project_per_month'',
		15110,
		15000,
		''select count(*) from im_projects where start_date > now()::date-30 and start_date <= now()::date'',
		0,
		300,
		5
	);

	update im_indicators set
		indicator_section_id = 15205
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Actually counts the number of main projects (no subprojects) starting in the last 30 days.''
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
		''New customers per month'',
		''new_countsers_per_month'',
		15110,
		15000,
		''select count(*)
from acs_objects o, im_companies c
where
    o.object_id = c.company_id
    and c.company_type_id in (select child_id from im_category_hierarchy where parent_id = 57 UNION select 57)
    and o.creation_date > now()::date-30'',
		0,
		30,
		5
	);

	update im_indicators set
		indicator_section_id = 15205
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts how many customer objects have been created in the last 30 days. However, this indicator doesn''''t say whether these new customers have generated any revenues.''
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
		'']po[ Live Operations Time'',
		''po_live'',
		15110,
		15000,
		''select now()::date - min(start_date)::date from im_projects;'',
		0,
		100,
		5
	);

	update im_indicators set
		indicator_section_id = 15245
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the days ]po[ is in operations, starting with the start_date of the first project.''
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
		''Forum Use'',
		''forum_use'',
		15110,
		15000,
		''select count(*) from im_forum_topics where posting_date > now()::date - 30'',
		0,
		100,
		5
	);

	update im_indicators set
		indicator_section_id = 15245
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of forum items created in the last 30 days.''
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
		''Active customers last month'',
		''active_customers_last_month'',
		15110,
		15000,
		''select count(*) from (
select distinct company_id 
from im_projects
where start_date > now()::date-30
) t
'',
		0,
		50,
		5
	);

	update im_indicators set
		indicator_section_id = 15205
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of customers with projects in the last 30 days.''
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
		''Financial Documents per Project'',
		''findocs_per_project'',
		15110,
		15000,
		''select round(avg(cnt),1) from (
select  count(*) as cnt,
        parent.project_id
from    im_costs c,
        im_projects parent,
        im_projects p
where   parent.parent_id is null and
        parent.end_date between now()::date-60 and now()::date-30 and
        p.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
        c.project_id = p.project_id and
        c.cost_type_id not in (3716, 3718, 3720, 3714)
group by parent.project_id) t
;
'',
		0,
		5,
		5
	);

	update im_indicators set
		indicator_section_id = 15245
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts how many financial documents (quotes, pos, invoices, bills, deliver notes or expense invoices) have been generated for all main projects that ended (end_date) 30 days ago to 60 days ago.''
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
		''1'',
		''einz'',
		15110,
		15000,
		''select 1'',
		0,
		2,
		5
	);

	update im_indicators set
		indicator_section_id = NULL
	where indicator_id = v_id;

	update im_reports set
		report_description = ''''
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
		''Revenues'',
		''revenues'',
		15110,
		15000,
		''select round(sum(amount),0) from im_costs where cost_type_id = 3700 and effective_date between now()::date-60 and now()::date-30'',
		0,
		1000,
		5
	);

	update im_indicators set
		indicator_section_id = 15200
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Invoices written with effective date between 30 days and 60 days ago.''
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
		15110,
		15000,
		''select round(sum(amount),0) from im_costs where cost_type_id = 3704 and effective_date between now()::date-60 and now()::date-30'',
		0,
		1000,
		5
	);

	update im_indicators set
		indicator_section_id = 15200
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Provider bills with effective date between 30 days ago and 60 days ago.''
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
		''Sick Days per Month'',
		''sick_days'',
		15110,
		15000,
		''select round(
(select  count(*) * 100.0
from    im_user_absences a,
        im_day_enumerator(now()::date-60, now()::date-30) days
where   days between a.start_date and a.end_date and
        a.absence_type_id = 5002 and
        a.owner_id in (select member_id from group_distinct_member_map where group_id = 463))
/
(select sum(coalesce(availability, 100)) as availability
from    im_employees e
where   e.employee_id in (select member_id from group_distinct_member_map where group_id = 463))
,1);'',
		0,
		5,
		5
	);

	update im_indicators set
		indicator_section_id = 15235
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of sick days per full-time employee (using the ''''availability'''' field of the Employee)''
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
		''Projects per PM'',
		''p0001'',
		15110,
		15000,
		''select 
round((select count(*) 
from im_projects 
where start_date > now()::date-30 and start_date <= now()::date) * 1.0 /
(select 1+count(*) from (select distinct project_lead_id from im_projects where start_date > now()::date-30 and start_date <= now()::date) t)
,1)'',
		0,
		100,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts how many projects each PM has started in the last 30 days.''
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
		''Headcount'',
		''headcount'',
		15110,
		15000,
		''select count(*) 
from users_active u, group_distinct_member_map gm
where 
u.user_id = gm.member_id and 
gm.group_id = (select group_id from groups where group_name = ''''Employees'''')'',
		0,
		20,
		5
	);

	update im_indicators set
		indicator_section_id = 15235
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts all members of group ''''Employees''''.''
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
		''Average Employee Time in the Company'',
		''employee_rotation'',
		15110,
		15000,
		''select round(avg(end_date - start_date),0)
from
        (select
                rc.start_date::date as start_date,
                CASE WHEN rc.end_date::date > now() THEN now()::date ELSE rc.end_date::date END as end_date
        from
                im_employees e,
                im_costs c,
                im_repeating_costs rc,
                users_active u
        where
                e.employee_id = u.user_id and
                c.cost_id = rc.rep_cost_id and
                c.cause_object_id = u.user_id and
                e.employee_id in (select member_id from group_distinct_member_map where group_id = 463)
        ) t
;
'',
		0,
		200,
		5
	);

	update im_indicators set
		indicator_section_id = 15235
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Returns the average time (in days) the currently active Employees stay in the company (employee end_date - start_date).''
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
		''Net Margin Two Months Ago'',
		''net_margin'',
		15110,
		15000,
		''select
        round((invoices - bills - timesheet - expenses) / (invoices+0.000001) * 100, 1) as net_margin
from

        (select
        (select sum(amount) from im_costs where cost_type_id = 3700 and effective_date between now()::date-60 and now()::date-30) as invoices,
        (select sum(amount) from im_costs where cost_type_id = 3702 and effective_date between now()::date-60 and now()::date-30) as quotes,
        (select sum(amount) from im_costs where cost_type_id = 3704 and effective_date between now()::date-60 and now()::date-30) as bills,
        (select sum(amount) from im_costs where cost_type_id = 3706 and effective_date between now()::date-60 and now()::date-30) as pos,
        (select sum(amount) from im_costs where cost_type_id = 3718 and effective_date between now()::date-60 and now()::date-30) as timesheet,
        (select sum(amount) from im_costs where cost_type_id = 3720 and effective_date between now()::date-60 and now()::date-30) as expenses
        ) base
;
'',
		0,
		20,
		5
	);

	update im_indicators set
		indicator_section_id = 15200
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates ((Invoices - Bills - Timesheet - Expenses) / Invoices) of all financial documents between now-30 days and now-60 days.''
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
		''Forum Items in the last 30 days'',
		''forum_items'',
		15110,
		15000,
		''select  count(*)
from    im_forum_topics t, im_projects p
where   p.project_id = t.object_id and
        posting_date > now()::date-30
;
'',
		0,
		10,
		5
	);

	update im_indicators set
		indicator_section_id = 15245
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of forum items posted in the last 30 days.''
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
		''Preliminary Bruto Margin Two Months Ago'',
		''prelim_bruto_margin'',
		15110,
		15000,
		''select
        round((quotes - pos) / (quotes+0.000001) * 100,1) as prelim_brut_margin
from

        (select
        (select sum(amount) from im_costs where cost_type_id = 3700 and effective_date between now()::date-60 and now()::date-30) as invoices,
        (select sum(amount) from im_costs where cost_type_id = 3702 and effective_date between now()::date-60 and now()::date-30) as quotes,
        (select sum(amount) from im_costs where cost_type_id = 3704 and effective_date between now()::date-60 and now()::date-30) as bills,
        (select sum(amount) from im_costs where cost_type_id = 3706 and effective_date between now()::date-60 and now()::date-30) as pos,
        (select sum(amount) from im_costs where cost_type_id = 3718 and effective_date between now()::date-60 and now()::date-30) as timesheet,
        (select sum(amount) from im_costs where cost_type_id = 3720 and effective_date between now()::date-60 and now()::date-30) as expenses
        ) base
;'',
		0,
		60,
		5
	);

	update im_indicators set
		indicator_section_id = 15200
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Calculates ((Quotes - POs) / Quotes) of all financial documents effective between now-30 and now-60 (the 2nd last month).''
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
		''Average Number of Open Projects per PM'',
		''open_projects_per_PM'',
		15110,
		15000,
		''select  round(avg(cnt),1)
from    (
        select  count(*) as cnt,
                p.project_lead_id
        from    im_projects p
        where   p.parent_id is null and
                p.project_status_id in (select * from im_sub_categories(76))
        group by p.project_lead_id
        )t
;'',
		0,
		10,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the number of currently open projects and divides by the number of its project managers.''
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
		''Active PMs'',
		''active_pms'',
		15110,
		15000,
		''select count(*) from (select distinct project_lead_id from im_projects where project_status_id in (select * from im_sub_categories(76))) t'',
		0,
		20,
		5
	);

	update im_indicators set
		indicator_section_id = 15210
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts how many different PMs are dealing with the currently open projects.''
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
    
