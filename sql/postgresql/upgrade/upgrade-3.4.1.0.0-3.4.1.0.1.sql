-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');




-- Creation Date
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_dept_id'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_dept_id			integer
					constraint im_ticket_dept_fk
					references im_cost_centers;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'service_level_agreements', 'Service Level Agreements', 'Service Level Agreements',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	
			p.project_id,
			p.project_name
		from 
			im_projects p
		where 
			p.project_type_id = 2502 and
			p.project_status_id in (select * from im_sub_categories(76))
		order by 
			lower(project_name) 
	}}}'
);


-----------------------------------------------------------
-- Hard coded fields
--
SELECT im_dynfield_attribute_new ('im_ticket', 'project_name', 'Name', 'textbox_medium', 'string', 'f', 00, 't', 'im_projects');

SELECT im_dynfield_attribute_new (
	'im_ticket', 'parent_id', 'Service Level Agreement', 'service_level_agreements', 
	'integer', 'f', 10, 't', 'im_projects'
);

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_status_id', 'Status', 'ticket_status', 'integer', 'f', 20, 't', 'im_tickets');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_type_id', 'Type', 'ticket_type', 'integer', 'f', 30, 't', 'im_tickets');



-----------------------------------------------------------
-- Other fields
--

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_prio_id', 'Priority', 'ticket_priority', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_assignee_id', 'Assignee', 'ticket_assignees', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_note', 'Note', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_component_id', 'Software Component', 'ticket_po_components', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_conf_item_id', 'Hardware Component', 'conf_items_servers', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_description', 'Description', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_deadline', 'Desired Customer End Date', 'date', 'date', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quoted_days', 'Quoted Days', 'numeric', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quote_comment', 'Quote Comment', 'textarea_small_nospell', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_request_type_id', 'Telephony Request Type', 'telephony_request_type', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_old_number', 'Old Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_new_number', 'New Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_contact_id', 'Customer Contact', 'customer_contact', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_dept_id', 'Department', 'cost_centers', 'integer', 'f');

-----------------------------------------------------------
-- Unused fields
--

-- ticket_service_id                | integer                  |
-- ticket_hardware_id               | integer                  |
-- ticket_application_id            | integer                  |
-- ticket_queue_id                  | integer                  |
-- ticket_alarm_date                | timestamp with time zone |
-- ticket_alarm_action              | text                     |
-- ticket_creation_date             | timestamp with time zone |
-- ticket_reaction_date             | timestamp with time zone |
-- ticket_confirmation_date         | timestamp with time zone |
-- ticket_done_date                 | timestamp with time zone |
-- ticket_signoff_date              | timestamp with time zone |
-- ocs_software_id                  | integer                  |

