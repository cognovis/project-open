-- upgrade-4.0.3.0.6-4.0.3.0.7.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.6-4.0.3.0.7.sql','');



update im_dynfield_attributes
set also_hard_coded_p = 't'
where acs_attribute_id in (
	select	attribute_id
	from	acs_attributes
	where	object_type = 'im_project' and
		attribute_name in (
'end_date', 
'project_budget_hours', 
'company_id', 
'description', 
'note', 
'on_track_status_id', 
'parent_id', 
'percent_completed', 
'project_budget', 
'project_budget_currency', 
'project_lead_id', 
'project_name', 
'project_nr', 
'project_path', 
'project_status_id', 
'project_type_id'
		)
	)
;

