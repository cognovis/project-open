-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');


SELECT im_dynfield_attribute_new ('im_company', 'company_name', 'Name', 'textbox_medium', 'string', 'f', 0, 't', 'im_companies');


SELECT im_dynfield_attribute_new ('im_company', 'company_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'main_office_id', 'Main Office', 'offices', 'integer', 'f', 20, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_status_id', 'Status', 'category_company_status', 'integer', 'f', 30, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_type_id', 'Type', 'category_company_type', 'integer', 'f', 40, 't', 'im_companies');




SELECT im_dynfield_attribute_new ('im_project', 'project_name', 'Name', 'textbox_large', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_nr', 'Nr', 'textbox_medium', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'parent_id', 'Parent Project', 'im_parent_projects', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'company_id', 'Customer', 'customers', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_type_id', 'Project Type', 'category_project_type', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_status_id', 'Project Status', 'category_project_status', 'string', 'f', 10, 't');

SELECT im_dynfield_attribute_new ('im_project', 'description', 'Description', 'textarea', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'note', 'Note', 'textarea', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_lead_id', 'Project Manager', 'project_managers', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'supervisor_id', 'Project Sponsor', 'project_sponsors', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_budget', 'Budget', 'number', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'percent_completed', '% Done', 'number', 'string', 'f', 10, 't');



SELECT im_dynfield_attribute_new ('im_project', 'on_track_status_id', 'On Track', 'traffic_light_status', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_budget_currency', 'Budget Currency', 'currency', 'string', 'f', 10, 't');

-- SELECT im_dynfield_attribute_new ('im_project', 'project_budget_hours', 'Budget Hours', 'numeric', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'end_date', 'End', 'date', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'start_date', 'Start', 'date', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'template_p', 'Template?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'company_contact_id', 'Customer Contact', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'company_project_nr', 'Customer PO Number', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'confirm_date', 'Confirm Date', 'date', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'release_item_p', 'Release Item?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'milestone_p', 'Milestone?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'presales_probability', 'Presales Probability', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'presales_value', 'Presales Value', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'project_priority_id', 'Project Priority', 'string', 'f', 10, 't');
