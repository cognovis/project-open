<?xml version="1.0"?>
<queryset>

<fullquery name="panels">      
      <querytext>
      
    select tp.header, 
           tp.template_url,
           '' as bgcolor
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and :this_user_is_assigned_p = 1))
       and tp.overrides_action_p = 'f'
    order by tp.sort_order

      </querytext>
</fullquery>

 
<fullquery name="instruction_check">      
      <querytext>
      
    select count(*) 
    from wf_transition_info ti, wf_tasks t
    where t.task_id = :task_id
      and t.transition_key = ti.transition_key
      and t.workflow_key = ti.workflow_key
      and instructions is not null

      </querytext>
</fullquery>

 
<fullquery name="action_panels">      
      <querytext>
      
    select tp.header, 
           tp.template_url
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and :this_user_is_assigned_p = 1))
       and tp.overrides_action_p = 't'
    order by tp.sort_order

      </querytext>
</fullquery>

 
<fullquery name="case_state">      
      <querytext>
      select state from wf_cases where case_id = :case_id
      </querytext>
</fullquery>

 
</queryset>
