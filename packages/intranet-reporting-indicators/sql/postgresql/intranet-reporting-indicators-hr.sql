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
		''Projects per PM'',
		''p0001'',
		15110,
		15000,
		''select 
round((select count(*) 
from im_projects 
where start_date > now()::date-30 and start_date <= now()::date) * 1.0 /
(select (count(*)*1.0 + 0.00000000001) from (select distinct project_lead_id from im_projects where start_date > now()::date-30 and start_date <= now()::date) t)
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
    


-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=3, indicator_low_warn=4, indicator_high_warn=6, indicator_high_critical=8
where indicator_id in (select report_id from im_reports where report_code = 'open_projects_per_PM');

