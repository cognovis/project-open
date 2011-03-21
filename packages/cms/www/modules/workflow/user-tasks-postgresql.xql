<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_party_name">      
      <querytext>
      
  select coalesce(party__name(:party_id),person__name(:party_id)) 

      </querytext>
</fullquery>

 
<fullquery name="get_active">      
      <querytext>
      
  select
    trans.transition_key, transition_name, 
    item_id, content_item__get_title(item_id,'f') as title,
    t.state,
    to_char(deadline,'Mon. DD, YYYY') as deadline_pretty,
    to_char(enabled_date,$date_format) as enabled_date_pretty,
    to_char(started_date,$date_format) as started_date_pretty,
    to_char(hold_timeout,'Mon. DD, YYYY') as hold_timeout_pretty,
    holding_user, person__name(holding_user) as holding_user_name,
    content_workflow__is_overdue(c.case_id, trans.transition_key) as is_overdue
  from
    wf_transitions trans, wf_tasks t, cr_items i,
    wf_cases c, wf_case_assignments ca
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.case_id = ca.case_id
  and
    c.case_id = t.case_id
  and
    c.object_id = i.item_id
  and
    t.transition_key = trans.transition_key
  and
    ca.role_key = trans.role_key
  and
    c.state = 'active'
  and
    t.state in ('enabled','started')
  and
    ca.party_id = :party_id
  order by
    trans.sort_order, title
      </querytext>
</fullquery>

 
<fullquery name="get_waiting">      
      <querytext>
      
  select
    trans.transition_key, transition_name, 
    item_id, content_item__get_title(item_id) as title,
    to_char(deadline,'Mon. DD, YYYY') as deadline_pretty,
    content_workflow__is_overdue(c.case_id, trans.transition_key) as is_overdue
  from
    wf_case_assignments ca, wf_case_deadlines dead, wf_cases c,
    cr_items i, wf_transitions trans
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.case_id = ca.case_id
  and
    c.case_id = dead.case_id
  and
    ca.role_key = trans.role_key
  and
    dead.transition_key = trans.transition_key
  and
    c.object_id = i.item_id
  and
    c.state = 'active'
  and
    content_workflow__is_finished(c.case_id, trans.transition_key) = 'f'
  and
    not exists ( select 1
                 from
                   wf_tasks
                 where
                   case_id = c.case_id
                 and
                   transition_key = trans.transition_key
                 and
                   state in ('enabled','started') )
  and
    ca.party_id = :party_id
  order by
    trans.sort_order, title
      </querytext>
</fullquery>

 
</queryset>
