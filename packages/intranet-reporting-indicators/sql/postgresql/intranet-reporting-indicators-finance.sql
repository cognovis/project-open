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
    
    




-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=10000, indicator_low_warn=20000, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'revenues');

