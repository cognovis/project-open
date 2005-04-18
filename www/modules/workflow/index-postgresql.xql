<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_stats">      
      <querytext>

  select
    count( case when content_workflow__is_finished(c.case_id, transition_key) = 'f' then 1 else null end
    ) as total_count,
    count( case when content_workflow__is_overdue(c.case_id, transition_key) = 't' then 1 else null end
    ) as overdue_count,
    count( case when content_workflow__is_active(c.case_id, transition_key) = 't' then 1 else null end
    ) as active_count,
    count( case when content_workflow__is_checked_out(c.case_id, transition_key) = 't' then 1 else null end
    ) as checkout_count
  from
    wf_cases c, wf_transitions trans
  where
    c.workflow_key = trans.workflow_key
  and
    c.workflow_key = 'publishing_wf'
  and
    c.state = 'active'

      </querytext>
</fullquery>

 
<fullquery name="get_transitions">      
      <querytext>

  select 
    trans.transition_key, transition_name, sort_order,
    count(transition_name) as transition_count,
    count( case when content_workflow__is_overdue(c.case_id, trans.transition_key) = 't' then 1 else null end
         ) as overdue_count,
    count(case  when content_workflow__is_active(c.case_id, trans.transition_key) = 't' then 1 else null end
         ) as active_count,
    count( case when content_workflow__is_checked_out(c.case_id, trans.transition_key) = 't' then 1 else null end
         ) as checkout_count
  from
    wf_cases c, wf_transitions trans
  where
    trans.workflow_key = c.workflow_key
  and
    trans.workflow_key = 'publishing_wf'
  and
    c.state in ('active')
  and
    -- don't include tasks that have been finished or canceled
    content_workflow__is_finished(c.case_id, trans.transition_key) = 'f'
  group by
    sort_order, transition_name, trans.transition_key

      </querytext>
</fullquery>

 
<fullquery name="get_user_tasks">      
      <querytext>

  select
    p.person_id, p.first_names, p.last_name,
    count(transition_name) as transition_count,
    count(case when content_workflow__is_overdue(c.case_id, t.transition_key) = 't' then 1 else null end
         ) as overdue_count,
    count(case when content_workflow__is_active(c.case_id, t.transition_key) = 't' then 1 else null end
         ) as active_count,
    count( case when content_workflow__is_checked_out(c.case_id, t.transition_key, ca.party_id) = 't' then 1 else null end 
         ) as checkout_count
  from
    wf_cases c, wf_case_assignments ca, 
    wf_transitions t, persons p
  where
    t.workflow_key = 'publishing_wf'
  and
    t.workflow_key = c.workflow_key
  and
    c.state = 'active'
  and
    c.case_id = ca.case_id
  and
    ca.role_key = t.role_key
  and
    p.person_id = ca.party_id
  and
    -- don't include tasks that have been finished or canceled
    content_workflow__is_finished(c.case_id, t.transition_key) = 'f'
  group by
    first_names, last_name, person_id 

      </querytext>
</fullquery>

 
</queryset>
