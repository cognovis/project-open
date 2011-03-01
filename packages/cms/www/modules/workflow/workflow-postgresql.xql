<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_active">      
      <querytext>
      
  select
    t.transition_key, transition_name, 
    item_id, content_item__get_title(item_id,'f') as title,
    t.state, ca.party_id,
    coalesce(party__name(ca.party_id),person__name(ca.party_id)) as assigned_party,
    holding_user,
    person__name(holding_user) as holding_user_name,
    to_char(hold_timeout,'Mon. DD, YYYY') as hold_timeout_pretty,
    to_char(deadline,'Mon., DD, YYYY') as deadline_pretty,
    to_char(enabled_date,$date_format) as enabled_date_pretty, 
    to_char(started_date,$date_format) as started_date_pretty,
    content_workflow__is_overdue(c.case_id, t.transition_key) as is_overdue
  from
    wf_tasks t, wf_transitions trans, cr_items i,
    wf_cases c, wf_case_assignments ca
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.case_id = t.case_id
  and
    c.case_id = ca.case_id
  and
    c.state = 'active'
  and
    -- the workflow item is a content item
    c.object_id = i.item_id
  and
    t.transition_key = trans.transition_key
  and
    ca.role_key = trans.role_key
  and
    t.state in ('started','enabled')
  $transition_sql
  order by
    trans.sort_order, title, assigned_party, deadline desc, state

      </querytext>
</fullquery>

 
<fullquery name="get_waiting">      
      <querytext>
      
  select
    trans.transition_key, transition_name, ca.party_id,
    item_id, content_item__get_title(item_id,'f') as title,
    coalesce(party__name(ca.party_id),person__name(ca.party_id)) as assigned_party,
    to_char(dead.deadline,'Mon.DD, YYYY') as deadline_pretty,
    content_workflow__is_overdue(c.case_id, trans.transition_key) as is_overdue
  from
    wf_cases c, wf_case_assignments ca, wf_case_deadlines dead,
    wf_transitions trans, cr_items i
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.object_id = i.item_id
  and
    c.case_id = ca.case_id
  and
    c.case_id = dead.case_id
  and
    ca.role_key = trans.role_key
  and
    dead.transition_key = trans.transition_key
  and
    c.state = 'active'
  and
    -- non active task
    not exists ( select 1
                 from 
                   wf_tasks
                 where
                   state in ('enabled','started')
                 and
                   case_id = c.case_id
                 and
                   transition_key = trans.transition_key )
  and
    -- its finished
    content_workflow__is_finished(c.case_id, trans.transition_key) = 'f'
  -- trans.transition_key = transition 
  $transition_sql
  order by
    trans.sort_order, title, assigned_party, dead.deadline desc
      </querytext>
</fullquery>

 
</queryset>
