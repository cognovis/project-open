-- upgrade-3.4.0.7.0-3.4.0.7.1.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.4.0.7.0-3.4.0.7.1.sql','');

update im_reports SET report_sql = 'select 
round(
	(select	count(*) 
	from	im_projects 
	where	start_date > now()::date-30 and start_date <= now()::date) * 1.0 /
	(select	(count(*)*1.0 + 0.00000000001) 
	from	(select distinct 
		project_lead_id 
		from im_projects 
		where	start_date > now()::date-30 and 
			start_date <= now()::date
		) t
	)
,1)'
where report_name = 'Projects per PM';


update im_indicators set
	indicator_low_critical=5, indicator_low_warn=10, indicator_high_warn=40, indicator_high_critical=45
where indicator_id in (select report_id from im_reports where report_code = 'active_customers_last_month');

update im_indicators set
	indicator_low_critical=2, indicator_low_warn=5, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'new_countsers_per_month');

update im_indicators set
	indicator_low_critical=10, indicator_low_warn=20, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'new_project_per_month');

update im_indicators set
	indicator_low_critical=10000, indicator_low_warn=20000, indicator_high_warn=null, indicator_high_critical=null
where indicator_id in (select report_id from im_reports where report_code = 'revenues');

update im_indicators set
	indicator_low_critical=3, indicator_low_warn=4, indicator_high_warn=6, indicator_high_critical=8
where indicator_id in (select report_id from im_reports where report_code = 'open_projects_per_PM');

