<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="finished_tasks">      
      <querytext>
      
    select t.task_id, 
           t.transition_key, 
           t.state, 
           t.case_id,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty,
           to_char(t.started_date, :date_format) as started_date_pretty,
           to_char(t.canceled_date, :date_format) as canceled_date_pretty,
           to_char(t.overridden_date, :date_format) as overridden_date_pretty,
           to_char(t.finished_date, :date_format) as finished_date_pretty,
           to_char(nvl(t.finished_date, nvl(t.canceled_date, t.overridden_date)), :date_format) as done_date_pretty,
           p.party_id as done_by_party_id,
           '' as done_by_url,
           acs_object.name(p.party_id) as done_by_name,
           p.email as done_by_email
      from wf_tasks t, wf_transitions tr, parties p
     where t.case_id = :case_id
       and t.state not in ('enabled', 'started')
       and tr.workflow_key = t.workflow_key
       and tr.transition_key = t.transition_key
       and p.party_id (+) = t.holding_user
     order by t.enabled_date desc

      </querytext>
</fullquery>

 
</queryset>
