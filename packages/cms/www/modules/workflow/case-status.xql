<?xml version="1.0"?>
<queryset>

<fullquery name="get_caseinfo">      
      <querytext>
      select case_id, initcap(state) as state
           from wf_cases where object_id = :item_id
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      select case when count(*) = 0 then 'no' else 'yes' end
               from wf_case_assignments ca,
		    wf_transitions trans
               where case_id = :case_id 
	       and ca.role_key = trans.role_key
               and trans.transition_key = :transition_key 
               and party_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
