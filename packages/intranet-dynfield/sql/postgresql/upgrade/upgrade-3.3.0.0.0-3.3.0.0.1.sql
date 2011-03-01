-- upgrade-3.3.0.0.0-3.3.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.3.0.0.0-3.3.0.0.1.sql','');




create or replace function im_insert_acs_object_type_tables (varchar, varchar, varchar) 
returns integer as $body$
DECLARE
	p_object_type		alias for $1;
	p_table_name		alias for $2;
	p_id_column		alias for $3;

	v_count			integer;
BEGIN
        -- Check for duplicates
	select	count(*) into v_count
	from	acs_object_type_tables
	where	object_type = p_object_type and
		table_name = p_table_name;
	IF v_count > 0 THEN return 1; END IF;

	-- Make sure the object_type exists
	select	count(*) into v_count
	from	acs_object_types
	where	object_type = p_object_type;
	IF v_count = 0 THEN return 2; END IF;

	insert into acs_object_type_tables (object_type, table_name, id_column)
	values (p_object_type, p_table_name, p_id_column);

	return 0;
end;$body$ language 'plpgsql';


SELECT im_insert_acs_object_type_tables('acs_activity','acs_activities','activity_id');
SELECT im_insert_acs_object_type_tables('acs_event','acs_events','event_id');
SELECT im_insert_acs_object_type_tables('authority','auth_authorities','authority_id');
SELECT im_insert_acs_object_type_tables('bt_bug','bt_bugs','bug_id');
SELECT im_insert_acs_object_type_tables('bt_bug_revision','bt_bug_revisions','bug_revision_id');
SELECT im_insert_acs_object_type_tables('bt_patch','bt_patches','patch_id');
SELECT im_insert_acs_object_type_tables('cal_item','cal_items','cal_item_id');
SELECT im_insert_acs_object_type_tables('calendar','calendars','calendar_id');
SELECT im_insert_acs_object_type_tables('group','groups','group_id');

SELECT im_insert_acs_object_type_tables('im_biz_object','im_biz_objects','object_id');
SELECT im_insert_acs_object_type_tables('im_biz_object_member','im_biz_object_members','rel_id');
SELECT im_insert_acs_object_type_tables('im_company','im_companies','company_id');
SELECT im_insert_acs_object_type_tables('im_company_employee_rel','im_company_employee_rel','employee_rel_id');
SELECT im_insert_acs_object_type_tables('im_component_plugin','im_component_plugins','plugin_id');
SELECT im_insert_acs_object_type_tables('im_conf_item','im_conf_items','conf_item_id');
SELECT im_insert_acs_object_type_tables('im_cost','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_cost_center','im_cost_centers','cost_center_id');
SELECT im_insert_acs_object_type_tables('im_dynfield_attribute','im_dynfield_attributes','attribute_id');
SELECT im_insert_acs_object_type_tables('im_dynfield_widget','im_dynfield_widgets','widget_id');
SELECT im_insert_acs_object_type_tables('im_expense','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_expense','im_expenses','expense_id');
SELECT im_insert_acs_object_type_tables('im_expense_bundle','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_expense_bundle','im_expense_bundles','bundle_id');
SELECT im_insert_acs_object_type_tables('im_forum_topic','im_forum_topics','topic_id');
SELECT im_insert_acs_object_type_tables('im_freelance_rfq','im_freelance_rfqs','rfq_id');
SELECT im_insert_acs_object_type_tables('im_freelance_rfq_answer','im_freelance_rfq_answers','answer_id');
SELECT im_insert_acs_object_type_tables('im_fs_file','im_fs_files','file_id');
SELECT im_insert_acs_object_type_tables('im_gantt_project','im_gantt_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_gantt_project','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_indicator','im_indicators','indicator_id');
SELECT im_insert_acs_object_type_tables('im_indicator','im_reports','report_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_investments','investment_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_repeating_costs','rep_cost_id');
SELECT im_insert_acs_object_type_tables('im_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_material','im_materials','material_id');
SELECT im_insert_acs_object_type_tables('im_menu','im_menus','menu_id');
SELECT im_insert_acs_object_type_tables('im_note','im_notes','note_id');
SELECT im_insert_acs_object_type_tables('im_office','im_offices','office_id');
SELECT im_insert_acs_object_type_tables('im_project','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_release_item','im_release_items','rel_id');
SELECT im_insert_acs_object_type_tables('im_repeating_cost','im_repeating_costs','rep_cost_id');
SELECT im_insert_acs_object_type_tables('im_repeating_cost','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_report','im_reports','report_id');
SELECT im_insert_acs_object_type_tables('im_rest_object_type','im_rest_object_types','object_type_id');
SELECT im_insert_acs_object_type_tables('im_ticket','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_ticket','im_tickets','ticket_id');
SELECT im_insert_acs_object_type_tables('im_ticket_queue','im_ticket_queue_ext','group_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_task','im_timesheet_tasks','task_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_task','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_trans_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_trans_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_trans_task','im_trans_tasks','task_id');
SELECT im_insert_acs_object_type_tables('im_user_absence','im_user_absences','absence_id');

SELECT im_insert_acs_object_type_tables('person','im_employees','employee_id');
SELECT im_insert_acs_object_type_tables('person','parties','party_id');
SELECT im_insert_acs_object_type_tables('person','persons','person_id');
SELECT im_insert_acs_object_type_tables('person','users_contact','user_id');

