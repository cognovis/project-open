<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_locked_tasks">      
      <querytext>
      
  select
    types.pretty_name, 
    obj.object_id item_id, 
    content_item.get_title(obj.object_id) title,
    task.task_id,
    content_workflow.get_holding_user_name(task.task_id) holding_user_name,
    to_char(task.hold_timeout,'Mon. DD, YYYY') hold_timeout,
    assign.case_id, 
    trans.transition_name, trans.transition_key,
    to_char(dead.deadline,'Mon. DD, YYYY') deadline
  from
    acs_object_types types,
    acs_objects obj,
    wf_case_assignments assign,
    wf_transitions trans, 
    wf_tasks task,
    wf_cases case,
    wf_case_deadlines dead,
    wf_transition_role_assign_map trans_role
  where 
    dead.case_id = case.case_id
  and
    dead.transition_key = task.transition_key
  and
    assign.party_id = :user_id
  and
    assign.case_id = task.case_id
  and
    assign.role_key = trans_role.assign_role_key
  and
    task.transition_key = trans_role.transition_key
  and 
    task.state = 'started'
  and
    task.transition_key = trans.transition_key
  and
    assign.case_id = case.case_id
  and
    case.object_id = obj.object_id
  and
    types.object_type = content_item.get_content_type(obj.object_id)
  and
    task.holding_user ^= :user_id
  order by
    dead.deadline

      </querytext>
</fullquery>

 
</queryset>
