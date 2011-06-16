-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');


SELECT im_dynfield_attribute_new ('im_company', 'company_name', 'Name', 'textbox_medium', 'string', 'f', 0, 't', 'im_companies');


SELECT im_dynfield_attribute_new ('im_company', 'company_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'main_office_id', 'Main Office', 'offices', 'integer', 'f', 20, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_status_id', 'Status', 'category_company_status', 'integer', 'f', 30, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_type_id', 'Type', 'category_company_type', 'integer', 'f', 40, 't', 'im_companies');




SELECT im_dynfield_attribute_new ('im_project', 'project_name', 'Name', 'textbox_large', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_nr, 'Nr', 'textbox_medium', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_path, 'Path', 'textbox_medium', 'string', 'f', 10, 't');
                 | character varying(100)   | not null
SELECT im_dynfield_attribute_new ('im_project', 'parent_id', 'Parent Project', 'im_parent_projects', 'string', 'f', 10, 't');
                    | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'tree_sortkey                 | bit varying              |
SELECT im_dynfield_attribute_new ('im_project', 'max_child_sortkey            | bit varying              |
SELECT im_dynfield_attribute_new ('im_project', 'company_id, 'Customer', 'customers', 'string', 'f', 10, 't');
                   | integer                  | not null
SELECT im_dynfield_attribute_new ('im_project', 'project_type_id', 'category_project_type', 'string', 'f', 10, 't');
              | integer                  | not null
SELECT im_dynfield_attribute_new ('im_project', 'project_status_id', 'category_project_status', 'string', 'f', 10, 't');
            | integer                  | not null
SELECT im_dynfield_attribute_new ('im_project', 'description', 'Description', 'textarea', 'string', 'f', 10, 't');
                  | character varying(4000)  |
SELECT im_dynfield_attribute_new ('im_project', 'note', 'Note', 'textarea', 'string', 'f', 10, 't');
                         | character varying(4000)  |
SELECT im_dynfield_attribute_new ('im_project', 'project_lead_id', 'Project Manager', 'project_managers', 'string', 'f', 10, 't');
              | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'supervisor_id', 'Project Sponsor', 'project_sponsors', 'string', 'f', 10, 't');
                | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'project_budget', 'Budget', 'number', 'string', 'f', 10, 't');
               | double precision         |
SELECT im_dynfield_attribute_new ('im_project', 'project_risk', 'Project Risk', 'textarea', 'string', 'f', 10, 't');
                 | character varying(1000)  |
SELECT im_dynfield_attribute_new ('im_project', 'corporate_sponsor', 'Corporate Sponsor', 'corporate_sponsor', 'string', 'f', 10, 't');
            | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'team_size                    | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'percent_completed', '% Done', 'number', 'f', 10, 't');
            | double precision         |
SELECT im_dynfield_attribute_new ('im_project', 'on_track_status_id', 'On Track', 'traffic_light_status', 'string', 'f', 10, 't');
           | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'project_budget_currency', 'Budget Currency', 'currency', 'string', 'f', 10, 't');
      | character(3)             |
SELECT im_dynfield_attribute_new ('im_project', 'project_budget_hours, 'Budget Hours', 'numeric', 'f', 10, 't');
         | double precision         |
SELECT im_dynfield_attribute_new ('im_project', 'end_date', 'End', 'date', 'f', 10, 't');
                     | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_project', 'start_date', 'Start', 'date', 'string', 'f', 10, 't');
                   | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_project', 'template_p', 'Template?', 'string', 'f', 10, 't');
                   | character(1)             | default 't'::bpchar
SELECT im_dynfield_attribute_new ('im_project', 'company_contact_id', 'Customer Contact', 'string', 'f', 10, 't');
           | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'company_project_nr', 'Customer PO Number', 'string', 'f', 10, 't');
           | character varying(50)    |
SELECT im_dynfield_attribute_new ('im_project', 'confirm_date', 'Confirm Date', 'date', 'string', 'f', 10, 't');
                 | date                     |
SELECT im_dynfield_attribute_new ('im_project', 'release_item_p', 'Release Item?', 'string', 'f', 10, 't');
               | character varying(1)     |
SELECT im_dynfield_attribute_new ('im_project', 'milestone_p', 'Milestone?', 'string', 'f', 10, 't');
                  | character(1)             |
SELECT im_dynfield_attribute_new ('im_project', 'presales_probability', 'Presales Probability', 'string', 'f', 10, 't');
         | numeric(5,2)             |
SELECT im_dynfield_attribute_new ('im_project', 'presales_value', 'Presales Value', 'string', 'f', 10, 't');
               | numeric(12,2)            |
SELECT im_dynfield_attribute_new ('im_project', 'reported_days_cache          | numeric(12,2)            | default 0
SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'string', 'f', 10, 't');
                   | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'project_priority_id, 'Project Priority', 'string', 'f', 10, 't');
          | integer                  |
SELECT im_dynfield_attribute_new ('im_project', 'sla_ticket_priority_map      | text                     |
SELECT im_dynfield_attribute_new ('im_project', 'risk_name                    | text                     |





SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_id                        | integer                  | not null
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_status_id', 'Status', 'string', 'f', 10, 't');
                 | integer                  | not null
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_type_id', 'Type', 'string', 'f', 10, 't');
                   | integer                  | not null
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_prio_id', 'Priority', 'string', 'f', 10, 't');
                   | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_contact_id', 'Customer Contact', 'string', 'f', 10, 't');
       | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_assignee_id', 'Assignee', 'string', 'f', 10, 't');
               | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_sla_id', 'SLA', 'string', 'f', 10, 't');
                    | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_dept_id', 'Department', 'string', 'f', 10, 't');
                   | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_service_id', 'Service', 'string', 'f', 10, 't');
                | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_hardware_id', 'Hardware', 'string', 'f', 10, 't');
               | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_application_id', 'Application', 'string', 'f', 10, 't');
            | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_queue_id', 'Queue', 'string', 'f', 10, 't');
                  | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_alarm_date', 'Alarm Date', 'date', 'string', 'f', 10, 't');
                | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_alarm_action', 'Alarm Action', 'string', 'f', 10, 't');
              | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_note', 'Note', 'string', 'f', 10, 't');
                      | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_conf_item_id', 'Conf Item', 'string', 'f', 10, 't');
              | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_component_id', 'Component', 'string', 'f', 10, 't');
              | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_description, 'Description', 'string', 'f', 10, 't');
               | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_deadline', 'Customer Deadline', 'string', 'f', 10, 't');
         | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quoted_days', 'Quoted Days', 'string', 'f', 10, 't');
               | double precision         |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quote_comment', 'Quote Comment', 'string', 'f', 10, 't');
             | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_request_type_id', 'Telephone Request Type', 'string', 'f', 10, 't');
 | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_old_number', 'Telephone Old Number', 'string', 'f', 10, 't');
      | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_new_number', 'Telephone New Number', 'string', 'f', 10, 't');
      | text                     |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_creation_date', 'Creation Date', 'date', 'string', 'f', 10, 't');
             | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_reaction_date, 'Reation Date', 'date', 'string', 'f', 10, 't');
             | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_confirmation_date, 'Confirmation Date', 'date', 'string', 'f', 10, 't');
         | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_done_date, 'Done Date', 'date', 'string', 'f', 10, 't');
                 | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_signoff_date, 'Signoff Date', 'date', 'string', 'f', 10, 't');
              | timestamp with time zone |
SELECT im_dynfield_attribute_new ('im_ticket', 'ocs_software_id', 'OCS Software', 'string', 'f', 10, 't');
                  | integer                  |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_resolution_time           | numeric(12,2)            |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_closed_in_1st_contact_p', 'Closed in first contact?', 'string', 'f', 10, 't');
   | character(1)             |
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_resolution_time_dirty     | timestamp with time zone |






SELECT im_dynfield_attribute_new ('im_timesheet_task', 'task_id                | integer          | not null
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'material_id', 'Material', 'string', 'f', 10, 't');
            | integer          | not null
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'uom_id', 'Unit of Measure', 'string', 'f', 10, 't');
                 | integer          | not null
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'planned_units', 'Planned Units', 'string', 'f', 10, 't');
          | double precision |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'billable_units', 'Billable Units', 'string', 'f', 10, 't');
         | double precision |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'cost_center_id', 'Cost Center', 'string', 'f', 10, 't');
         | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'invoice_id             | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'priority', 'Priority', 'string', 'f', 10, 't');
               | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'sort_order', 'Sort Order', 'string', 'f', 10, 't');
             | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'bt_bug_id              | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'gantt_project_id       | integer          |
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'risk_mitigation_action | text             |






SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_id                   | integer                 | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_name                 | character varying(100)  | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_label                | character varying(100)  | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_code                 | character varying(400)  | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_type_id              | integer                 | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'cost_center_status_id            | integer                 | not null
SELECT im_dynfield_attribute_new ('im_cost_center', 'department_p                     | character(1)            |
SELECT im_dynfield_attribute_new ('im_cost_center', 'parent_id                        | integer                 |
SELECT im_dynfield_attribute_new ('im_cost_center', 'manager_id                       | integer                 |
SELECT im_dynfield_attribute_new ('im_cost_center', 'description                      | character varying(4000) |
SELECT im_dynfield_attribute_new ('im_cost_center', 'note                             | character varying(4000) |
SELECT im_dynfield_attribute_new ('im_cost_center', 'department_planner_days_per_year | numeric                 |






