-- upgrade-3.4.0.8.4-3.4.0.8.5.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.0.8.4-3.4.0.8.5.sql','');


delete from im_view_columns where column_id = 27020;

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27020,270,20,'Name','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_name</A>"');


-- Called by "Enable" action of "Classify" WF transition.
-- Default classification routine. May be customized in order
-- to implement customers default ticket behaviour
--
create or replace function im_ticket__classify (integer,text,text)
returns integer as '
declare
	p_case_id		alias for $1;
	p_transition_key	alias for $2;
	p_custom_arg		alias for $3;

	v_task_id		integer;	v_case_id		integer;
	v_object_id		integer;	v_creation_user		integer;
	v_creation_ip		varchar;	v_journal_id		integer;
	v_transition_key	varchar;	v_workflow_key		varchar;

	v_ticket_id			integer;
	v_ticket_status_id		integer;
	v_ticket_type_id		integer;
	v_ticket_prio_id		integer;
	v_ticket_customer_contact_id	integer;
	v_ticket_assignee_id		integer;
	v_ticket_sla_id			integer;
	v_ticket_service_id		integer;
	v_ticket_hardware_id		integer;
	v_ticket_application_id		integer;
	v_ticket_queue_id		integer;
	v_ticket_queue			varchar;
	v_ticket_alarm_date		timestamp with time zone;
	v_ticket_alarm_action		text;
	v_ticket_note			text;
	v_ticket_conf_item_id		integer;

begin
	-- Select out some frequently used variables of the environment
	select	c.object_id, c.workflow_key, task_id, c.case_id
	into	v_object_id, v_workflow_key, v_task_id, v_case_id
	from	wf_tasks t, wf_cases c
	where	c.case_id = p_case_id
		and t.case_id = c.case_id
		and t.workflow_key = c.workflow_key
		and t.transition_key = p_transition_key;

	-- Select out all interesting variables from a ticket
	select	ticket_id, ticket_status_id, ticket_type_id, ticket_prio_id, ticket_customer_contact_id,
		ticket_assignee_id, p.parent_id as ticket_sla_id, ticket_service_id, ticket_hardware_id,
		ticket_application_id, ticket_queue_id, ticket_alarm_date, ticket_alarm_action, ticket_note,
		ticket_conf_item_id
	into	v_ticket_id, v_ticket_status_id, v_ticket_type_id, v_ticket_prio_id, v_ticket_customer_contact_id,
		v_ticket_assignee_id, v_ticket_sla_id, v_ticket_service_id, v_ticket_hardware_id,
		v_ticket_application_id, v_ticket_queue_id, v_ticket_alarm_date, v_ticket_alarm_action, v_ticket_note,
		v_ticket_conf_item_id
	from	im_tickets t, im_projects p
	where	t.ticket_id = p.project_id and
		t.ticket_id = v_object_id;

	-- Determine the queue for the ticket
	--
	-- Check if the ticket_queue has already been defined by the user or
	-- otherwise. Dont overwrite this queue.
	IF v_ticket_queue_id is null THEN

		-- Pull out the ticket queue name from ticket_type_id category
		select	group_id, group_name into v_ticket_queue_id, v_ticket_queue
		from	im_categories c, groups g
		where	c.category_id = v_ticket_type_id and
			trim(c.aux_string2) = trim(g.group_name);

		-- Check if we have found a valid group name in the im_categories.aux_string2 field:
		IF v_ticket_queue_id is not null THEN

			-- Set the que for the ticket
			update	im_tickets set ticket_queue_id = v_ticket_queue_id
			where	ticket_id = v_ticket_id;

			-- Protocol the decision to assign the ticket to that group.
			v_journal_id := journal_entry__new(
				null, v_case_id,
				v_transition_key || '' set_queue '' || p_custom_arg,
				v_transition_key || '' set_queue '' || p_custom_arg,
				now(), v_creation_user, v_creation_ip,
				''Ticket classify: Setting ticket queue to '' || 
				v_ticket_queue || '' based on Category '' || 
				im_category_from_id(v_ticket_type_id) || ''".''
			);

		END IF;
	END IF;
	
	return 0;
end;' language 'plpgsql';

