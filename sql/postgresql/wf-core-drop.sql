--
-- acs-workflow/sql/wf-core-drop.sql
--
-- Drops the data model and views for the workflow package.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

/* Drop all cases and all workflows */
create function inline_0 () returns integer as '
declare
        workflow_rec    record;
begin
    for workflow_rec in select w.workflow_key, t.table_name 
	 		   from wf_workflows w, acs_object_types t 
			  where t.object_type = w.workflow_key
    LOOP
        PERFORM workflow__delete_cases(workflow_rec.workflow_key);
	
        execute  ''drop table '' || workflow_rec.table_name;
        PERFORM workflow__drop_workflow(workflow_rec.workflow_key);
    end loop;

    return null;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


/* Sequences */
drop sequence t_wf_task_id_seq;
drop sequence t_wf_token_id_seq;

/* Views */
drop view wf_task_id_seq;
drop view wf_token_id_seq;
drop view wf_user_tasks;
drop view wf_enabled_transitions;
drop view wf_transition_places;
drop view wf_role_info;
drop view wf_transition_info;
drop view wf_transition_contexts;

/* Operational level */
drop table wf_attribute_value_audit;
drop table wf_tokens;
drop table wf_task_assignments;
drop table wf_tasks;
drop table wf_case_assignments;
drop table wf_case_deadlines;
drop table wf_cases;

/* Context level */
drop table wf_context_assignments;
drop table wf_context_task_panels;
drop table wf_context_role_info;
drop table wf_context_transition_info;
drop table wf_context_workflow_info;
drop table wf_contexts;

/* Knowledge Level */
drop table wf_transition_role_assign_map;
drop table wf_transition_attribute_map;
drop table wf_arcs;
drop table wf_transitions;
drop table wf_roles;
drop table wf_places;
drop table wf_workflows;

/* acs_object_type */

select acs_object_type__drop_type(
        'workflow',
        't'
    );


