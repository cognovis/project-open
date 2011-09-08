-- indicators-crm.sql

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
    




-- Update low and high level watermarks

update im_indicators set
	indicator_low_critical=5, indicator_low_warn=10, indicator_high_warn=40, indicator_high_critical=45
where indicator_id in (select report_id from im_reports where report_code = 'active_customers_last_month');

update im_indicators set
	indicator_low_critical=2, indicator_low_warn=5, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'new_countsers_per_month');

