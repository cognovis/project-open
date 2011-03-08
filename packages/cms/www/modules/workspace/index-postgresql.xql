<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_workspace_items">      
      <querytext>
      
  select
    types.pretty_name, 
    obj.object_id as item_id, 
    content_item__get_title(obj.object_id,'f') as title,
    task.task_id,
    task.holding_user,
    task.state,
    assign.case_id, 
    trans.transition_name, trans.transition_key,
    to_char(dead.deadline,'Mon. DD, YYYY') as deadline,
    content_workflow__can_reject(task.task_id, :user_id) as can_reject,
    content_workflow__approve_string(task.task_id, :user_id) as approve_string
  from
    acs_object_types types,
    acs_objects obj,
    wf_case_assignments assign,
    wf_transitions trans, 
    wf_tasks task,
    wf_cases cases,
    wf_case_deadlines dead
  where 
    dead.case_id = cases.case_id
  and
    dead.transition_key = task.transition_key
  and
    assign.party_id = :user_id
  and
    assign.case_id = task.case_id
  and
    assign.role_key = trans.role_key
  and
    task.transition_key = trans.transition_key
  and (
    task.state = 'enabled'
    or (task.state = 'started' and task.holding_user = :user_id)
  ) and
    task.transition_key = trans.transition_key
  and
    assign.case_id = cases.case_id
  and
    cases.object_id = obj.object_id
  and
    types.object_type = content_item__get_content_type(obj.object_id)
  order by
    dead.deadline

      </querytext>
</fullquery>

 
</queryset>










