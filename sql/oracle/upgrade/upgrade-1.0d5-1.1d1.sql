--
-- Upgrade script
--
-- Adds useful views
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$


create or replace view workflow_case_assigned_actions as 
    select c.workflow_id,
           c.case_id, 
           c.object_id,
           a.action_id, 
           a.assigned_role as role_id
    from   workflow_cases c,
           workflow_case_fsm cfsm,
           workflow_actions a,
           workflow_fsm_action_en_in_st aeis
    where  cfsm.case_id = c.case_id
    and    a.always_enabled_p = 'f'
    and    aeis.state_id = cfsm.current_state
    and    aeis.assigned_p = 't'
    and    a.action_id = aeis.action_id
    and    a.assigned_role is not null;

