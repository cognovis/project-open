<?xml version="1.0"?>
<queryset>
 
<fullquery name="current_tasks">      
      <querytext>
      
    select t.task_id, 
           t.transition_key, 
           t.state, 
           t.case_id,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty
    from   wf_tasks t, wf_transitions tr
    where  t.case_id = :case_id
    and    t.state in ('enabled', 'started')
    and    tr.workflow_key = t.workflow_key
    and    tr.transition_key = t.transition_key
    order by t.enabled_date desc

      </querytext>
</fullquery>

 
<fullquery name="old_tasks">      
      <querytext>
      
    select t.task_id, 
           t.transition_key, 
           t.state, 
           t.case_id,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty
    from   wf_tasks t, wf_transitions tr
    where  t.case_id = :case_id
    and    t.state not in ('enabled', 'started')
    and    tr.workflow_key = t.workflow_key
    and    tr.transition_key = t.transition_key
    order by t.enabled_date desc

      </querytext>
</fullquery>
 
</queryset>
