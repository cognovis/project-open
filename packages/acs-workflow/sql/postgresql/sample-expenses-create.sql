--
-- acs-workflow/sql/sample-expenses-create.sql
--
-- Creates an expenses workflow to play with.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

/* This table will hold one row for each case using this workflow. */
create table wf_expenses_cases (
  case_id 		integer primary key
			constraint wf_expenses_cases_case_fk
			references wf_cases on delete cascade
);


declare
    v_workflow_key wf_workflows.workflow_key%TYPE;
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_workflow_key := workflow.create_workflow(
	workflow_key => 'expenses_wf', 
	pretty_name => 'Expense Authorization', 
	pretty_plural => 'Expense authorizations', 
	description => 'Workflow for authorizing employee''s expenses on the company''s behalf', 
	table_name => 'wf_expenses_cases'
    );

    /*****
     * Places
     *****/

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'start',
        place_name => 'Start place',
        sort_order => 1
    );
    
    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'assignments_done',
        place_name => 'Tasks have been assigned',
        sort_order => 2
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'supervisor_to_approve',
        place_name => 'Supervisor is to approve',
        sort_order => 3
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'other_to_approve',
        place_name => 'Other is to approve',
        sort_order => 4
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'supervisor_approved',
        place_name => 'Supervisor has approved',
        sort_order => 5
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'other_approved',
        place_name => 'Other has approved',
        sort_order => 6
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'ready_to_buy',
        place_name => 'Both have approved',
        sort_order => 7
    );

    workflow.add_place(
        workflow_key => 'expenses_wf',
        place_key => 'end',
        place_name => 'End place',
        sort_order => 8
    );

    /*****
     * Roles
     *****/

    workflow.add_role(
        workflow_key => 'expenses_wf',
        role_key => 'assignor',
        role_name => 'Assignor',
        sort_order => 1
    );

    workflow.add_role(
        workflow_key => 'expenses_wf',
        role_key => 'supervisor',
        role_name => 'Supervisor',
        sort_order => 2
    );

    workflow.add_role(
        workflow_key => 'expenses_wf',
        role_key => 'other',
        role_name => 'Other approver',
        sort_order => 3
    );

    workflow.add_role(
        workflow_key => 'expenses_wf',
        role_key => 'requestor',
        role_name => 'Requestor',
        sort_order => 4
    );

    /*****
     * Transitions 
     *****/

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'assign',
        transition_name => 'Assign users to approval',
        role_key => 'assignor',
        sort_order => 1,
        trigger_type => 'user'
    );

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'and_split',
        transition_name => 'Parallel approval by supervisor and other',
        sort_order => 2,
        trigger_type => 'automatic'
    );

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'supervisor_approval',
        transition_name => 'Approve (Supervisor)',
        role_key => 'supervisor',
        sort_order => 3,
        trigger_type => 'user'
    );

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'other_approval',
        transition_name => 'Approve (Other)',
        role_key => 'other',
        sort_order => 4,
        trigger_type => 'user'
    );

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'and_join',
        transition_name => 'Re-synchronization from approval by supervisor and other',
        sort_order => 5,
        trigger_type => 'automatic'
    );

    workflow.add_transition(
        workflow_key => 'expenses_wf',
        transition_key => 'buy',
        transition_name => 'Buy stuff',
        role_key => 'requestor',
        sort_order => 6,
        trigger_type => 'user'
    );
        
    /*****
     * Arcs 
     *****/

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'start',
        to_transition_key => 'assign'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'assign',
        to_place_key => 'assignments_done'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'assignments_done',
        to_transition_key => 'and_split'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'and_split',
        to_place_key => 'supervisor_to_approve'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'and_split',
        to_place_key => 'other_to_approve'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'supervisor_to_approve',
        to_transition_key => 'supervisor_approval'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'supervisor_approval',
        to_place_key => 'supervisor_approved'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'other_to_approve',
        to_transition_key => 'other_approval'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'other_approval',
        to_place_key => 'other_approved'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'supervisor_approved',
        to_transition_key => 'and_join'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'other_approved',
        to_transition_key => 'and_join'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'and_join',
        to_place_key => 'ready_to_buy',
        guard_callback => 'wf_expenses.guard_both_approved_p',
        guard_description => 'Both Supervisor and the Other approver approved'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'and_join',
        to_place_key => 'end',
        guard_callback => '#',
        guard_description => 'Either Supervisor or the Other approver did not approve'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_place_key => 'ready_to_buy',
        to_transition_key => 'buy'
    );

    workflow.add_arc(
        workflow_key => 'expenses_wf',
        from_transition_key => 'buy',
        to_place_key => 'end'
    );

    /*****
     * Attributes
     *****/

    v_attribute_id := workflow.create_attribute(
	workflow_key => 'expenses_wf',
	attribute_name => 'supervisor_ok',
	datatype => 'boolean',
	pretty_name => 'Supervisor Approval',
	default_value => 'f',
        sort_order => 1
    );

    workflow.add_trans_attribute_map(
        workflow_key => 'expenses_wf',
        transition_key => 'supervisor_approval',
        attribute_name => 'supervisor_ok',
        sort_order => 1
    );

    v_attribute_id := workflow.create_attribute(
	workflow_key => 'expenses_wf',
	attribute_name => 'other_ok',
	datatype => 'boolean',
	pretty_name => 'Other Approval',
	default_value => 'f',
        sort_order => 2
    );

    workflow.add_trans_attribute_map(
        workflow_key => 'expenses_wf',
        transition_key => 'other_approval',
        attribute_name => 'other_ok',
        sort_order => 1
    );

    /*****
     * Assignment
     *****/

    workflow.add_trans_role_assign_map(
        workflow_key => 'expenses_wf',
        transition_key => 'assign',
        assign_role_key => 'supervisor'
    );

    workflow.add_trans_role_assign_map(
        workflow_key => 'expenses_wf',
        transition_key => 'assign',
        assign_role_key => 'other'
    );


end;
/
show errors





/* Context stuff */

insert into wf_context_transition_info (
    context_key, workflow_key, transition_key, estimated_minutes
) values (
    'default', 'expenses_wf', 'assign', 5
);

insert into wf_context_transition_info (
    context_key, workflow_key, transition_key, hold_timeout_callback, hold_timeout_custom_arg, estimated_minutes
) values (
    'default', 'expenses_wf', 'supervisor_approval', 'wf_callback.time_sysdate_plus_x', 1/24, 15
);

insert into wf_context_transition_info (
    context_key, workflow_key, transition_key, estimated_minutes
) values (
    'default', 'expenses_wf', 'other_approval', 15
);

insert into wf_context_transition_info (
    context_key, workflow_key, transition_key, estimated_minutes
) values (
    'default', 'expenses_wf', 'buy', 30
);


insert into wf_context_task_panels (
    context_key, workflow_key, transition_key, sort_order, header, template_url
) values (
    'default', 'expenses_wf', 'supervisor_approval', 1, 'Claim Info', 'sample/expenses-claim-info'
);

insert into wf_context_task_panels (
    context_key, workflow_key, transition_key, sort_order, header, template_url
) values (
    'default', 'expenses_wf', 'supervisor_approval', 2, 'Logic and Aids', 'sample/expenses-approval-aids'
);

insert into wf_context_task_panels (
    context_key, workflow_key, transition_key, sort_order, header, template_url
) values (
    'default', 'expenses_wf', 'other_approval', 1, 'Claim Info', 'sample/expenses-claim-info'
);

insert into wf_context_task_panels (
    context_key, workflow_key, transition_key, sort_order, header, template_url
) values (
    'default', 'expenses_wf', 'other_approval', 2, 'Logic and Aids', 'sample/expenses-approval-aids'
);

commit;



/* Callbacks for the workflow */

create or replace package wf_expenses
is

    function guard_both_approved_p (
	case_id in number,
	workflow_key in varchar2,
	transition_key in varchar2,
	place_key in varchar2,
	direction_in varchar2,
	custom_arg in varchar2
    )
    return char;

end wf_expenses;
/
show errors;


create or replace package body wf_expenses
is
    function guard_both_approved_p (
	case_id in number,
	workflow_key in varchar2,
	transition_key in varchar2,
	place_key in varchar2,
	direction_in varchar2,
	custom_arg in varchar2
    )
    return char
    is
	v_other_ok_p char(1);
	v_supervisor_ok_p char(1);
    begin
	v_other_ok_p := workflow_case.get_attribute_value(
	    case_id => guard_both_approved_p.case_id,
	    attribute_name => 'other_ok'
	);
	if v_other_ok_p = 'f' then
	    return 'f';
	end if;
	v_supervisor_ok_p := workflow_case.get_attribute_value(
	    case_id => guard_both_approved_p.case_id,
	    attribute_name => 'supervisor_ok'
	);
	return v_supervisor_ok_p;
    end guard_both_approved_p;

end wf_expenses;
/
show errors;

