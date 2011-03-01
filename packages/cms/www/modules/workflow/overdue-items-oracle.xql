<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_overdue_tasks">      
      <querytext>
      
  select
    trans.transition_key, transition_name, ca.party_id, 
    item_id, content_item.get_title(item_id) as title,
    nvl(party.name(ca.party_id),person.name(ca.party_id)) as assigned_party,
    to_char(dead.deadline,'Mon. DD, YYYY') as deadline_pretty,
    content_workflow.get_status(c.case_id, trans.transition_key) as status
  from 
    wf_transitions trans, wf_cases c, wf_case_deadlines dead, 
    wf_case_assignments ca, cr_items i
  where 
    c.case_id = dead.case_id
  and
    c.case_id = ca.case_id
  and
    ca.role_key = trans.role_key
  and
    dead.transition_key = trans.transition_key
  and
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.state = 'active'
  and 
    c.object_id = i.item_id
  and
    content_workflow.is_overdue(c.case_id, trans.transition_key) = 't'
  $transition_sql
  order by
    transition_name, dead.deadline desc, title, assigned_party

      </querytext>
</fullquery>

</queryset>
