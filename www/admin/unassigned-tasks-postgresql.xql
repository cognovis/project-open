<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unassigned_tasks">      
      <querytext>
      
    select ta.task_id,
           ta.case_id,
           ta.workflow_key,
           ta.transition_key,             
           tr.transition_name,
           ta.enabled_date,
           to_char(ta.enabled_date, :date_format) as enabled_date_pretty,
           ta.state,
           ta.deadline,
           to_char(ta.deadline, :date_format) as deadline_pretty,
           ta.estimated_minutes,
           c.object_id,
           acs_object__name(c.object_id) as object_name,
           o.object_type
    from   wf_tasks ta, wf_transitions tr, wf_cases c, acs_objects o
    where  ta.workflow_key = :workflow_key
    and    tr.workflow_key = ta.workflow_key
    and    tr.transition_key = ta.transition_key
    and    c.case_id = ta.case_id
    and    o.object_id = c.object_id
    and    ta.state = 'enabled'
    and    not exists (select 1 from wf_task_assignments tasgn where tasgn.task_id = ta.task_id)

      </querytext>
</fullquery>

 
</queryset>
