<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="active_tasks">      
      <querytext>
      
    select t.task_id, 
           t.transition_key, 
           t.state, 
           t.case_id,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty,
           to_char(t.started_date, :date_format) as started_date_pretty,
           to_char(t.deadline, :date_format) as deadline_pretty,
           p.party_id as assignee_party_id,
           p.email as assignee_email,
           acs_object.name(p.party_id) as assignee_name,
           '' as assignee_url,
           assignee_o.object_type as assignee_object_type,
           '' as reassign_url
      from wf_tasks t, wf_transitions tr, wf_task_assignments tasgn, parties p, acs_objects assignee_o
     where t.case_id = :case_id
       and t.state in ('enabled', 'started')
       and tr.workflow_key = t.workflow_key
       and tr.transition_key = t.transition_key
       and tasgn.task_id (+) = t.task_id
       and p.party_id (+) = tasgn.party_id
       and assignee_o.object_id (+) = p.party_id
    order by t.enabled_date desc

      </querytext>
</fullquery>

 
</queryset>
