<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_transinfo">      
      <querytext>
      select k.transition_key, k.task_id, t.transition_name,
             k.holding_user, 
             content_workflow__get_holding_user_name(k.task_id) as hold_name
             from wf_tasks k, wf_transitions t
	     where k.case_id = :case_id 
             and k.state in ('enabled', 'started')
             and k.transition_key = t.transition_key
      </querytext>
</fullquery>

 
<fullquery name="get_deadline">      
      <querytext>
      select to_char(deadline, 'DD MON') as deadline 
		 from wf_case_deadlines 
		 where case_id = :case_id 
                 and transition_key = :transition_key
      </querytext>
</fullquery>

 
</queryset>
