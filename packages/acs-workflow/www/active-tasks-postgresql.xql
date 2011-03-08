<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="active_tasks">      
      <querytext>

    select t.task_id, 
           t.transition_key,
           t.state, 
           t.case_id,
	   t.holding_user,
	   acs_object__name(t.holding_user) as holding_user_name,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty,
           to_char(t.started_date, :date_format) as started_date_pretty,
           to_char(t.deadline, :date_format) as deadline_pretty,
           p.party_id as assignee_party_id,
           p.email as assignee_email,
           acs_object__name(p.party_id) as assignee_name,
           '' as assignee_url,
           assignee_o.object_type as assignee_object_type,
           '' as reassign_url
      from (((wf_tasks t LEFT OUTER JOIN wf_task_assignments tasgn 
	     ON (t.task_id = tasgn.task_id)) LEFT OUTER JOIN parties p 
	       ON (tasgn.party_id = p.party_id)) LEFT OUTER JOIN acs_objects assignee_o 
		 ON (p.party_id = assignee_o.object_id)),
	   wf_transitions tr
     where t.case_id = :case_id
       and t.state in ('enabled', 'started')
       and tr.workflow_key = t.workflow_key
       and tr.transition_key = t.transition_key
    order by t.enabled_date desc

      </querytext>
</fullquery>

 
</queryset>
