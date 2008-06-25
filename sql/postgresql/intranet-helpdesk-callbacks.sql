-- /packages/intranet-helpdesk/sql/postgresql/intranet-helpdesk-callbacks.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Set the queue for the given ticket
--
create or replace function im_ticket__set_queue (integer,text,text)
returns integer as '
declare
	p_case_id		alias for $1;
	p_transition_key	alias for $2;
	p_custom_arg		alias for $3;

	v_task_id		integer;	v_case_id		integer;
	v_object_id		integer;	v_creation_user		integer;
	v_creation_ip		varchar;	v_journal_id		integer;
	v_transition_key	varchar;	v_workflow_key		varchar;

	v_queue_id		integer;
begin
	-- Select out some frequently used variables of the environment
	select	c.object_id, c.workflow_key, task_id, c.case_id
	into	v_object_id, v_workflow_key, v_task_id, v_case_id
	from	wf_tasks t, wf_cases c
	where	c.case_id = p_case_id
		and t.case_id = c.case_id
		and t.workflow_key = c.workflow_key
		and t.transition_key = p_transition_key;

	v_journal_id := journal_entry__new(
	    null, v_case_id,
	    v_transition_key || '' set_queue '' || p_custom_arg,
	    v_transition_key || '' set_queue '' || p_custom_arg,
	    now(), v_creation_user, v_creation_ip,
	    ''Setting ticket queue of "'' || acs_object__name(v_object_id) || ''" to "'' || 
	    p_custom_arg || ''".''
	);
	
	select group_id into v_queue_id
	from groups where trim(lower(group_name)) = trim(lower(p_custom_arg));

	IF v_queue_id is null THEN
		select group_id into v_queue_id
		from groups where group_name = ''Helpdesk'';
	END IF;
	
	update im_tickets
	set ticket_queue_id = v_queue_id
	where ticket_id = v_object_id;
	
	return 0;
end;' language 'plpgsql';



