-- Drop table data for the workflow package, part of the OpenACS system.
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @author Peter Marklund (peter@collaboraid.biz)
-- @creation-date 9 Januar 2003
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

declare
    foo integer;
begin
  for row in (select workflow_id from workflows)
  loop
    foo := workflow.del(row.workflow_id);
  end loop;
 
  acs_object_type.drop_type('workflow_lite', 't');
end;
/
show errors

begin
    content_type.drop_type (
        content_type => 'workflow_case_log_entry',
        drop_children_p => 't',
        drop_table_p => 't'
    );
end;
/
show errors


-- Drop all tables
drop table workflow_case_fsm;
drop table workflow_case_role_party_map;
drop view workflow_case_role_user_map;
drop table workflow_deputies;
drop table workflow_case_log_data;
drop table workflow_case_log;
drop table workflow_cases;
drop table workflow_fsm_action_en_in_st;
drop table workflow_fsm_actions;
drop table workflow_initial_action;
drop table workflow_fsm_states;
drop table workflow_action_callbacks;
drop table workflow_action_privileges;
drop table workflow_action_allowed_roles;
drop table workflow_actions;
drop table workflow_role_callbacks;
drop table workflow_role_allowed_parties;
drop table workflow_role_default_parties;
drop table workflow_roles;
drop table workflow_callbacks;
drop table workflows;

-- Drop sequences
drop sequence workflow_roles_seq;
drop sequence workflow_actions_seq;
drop sequence workflow_fsm_states_seq;
drop sequence workflow_cases_seq;
drop sequence workflow_case_log_seq;
