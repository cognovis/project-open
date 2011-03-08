<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="select_list">      
      <querytext>
      

   "t.task_id, 
    t.case_id, 
    t.transition_key, 
    t.enabled_date, 
    to_char(t.enabled_date, :date_format) as enabled_date_pretty,
    t.started_date,
    to_char(t.started_date, :date_format) as started_date_pretty,
    t.deadline,
    to_char(t.deadline, :date_format) as deadline_pretty,
    t.deadline::date - now()::date as days_till_deadline,
    t.state, 
    c.object_id, 
    ot.object_type as object_type,
    ot.pretty_name as object_type_pretty, 
    acs_object__name(c.object_id) as object_name,
    c.workflow_key,
    wft.pretty_name as workflow_name,
    now(),
    t.estimated_minutes,
    '' as task_url"

      </querytext>
</partialquery>
 
</queryset>
