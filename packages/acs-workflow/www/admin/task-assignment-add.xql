<?xml version="1.0"?>
<queryset>

<fullquery name="num_rows">      
      <querytext>
      
	select count(*) as num_rows 
	  from wf_transition_role_assign_map 
         where workflow_key = :workflow_key
	   and transition_key = :transition_key
	   and assign_role_key = :role_key
    
      </querytext>
</fullquery>

 
<fullquery name="make_manual">      
      <querytext>
      
	    insert into wf_transition_role_assign_map (workflow_key, transition_key, assign_role_key)
	    values (:workflow_key, :transition_key, :role_key)
	
      </querytext>
</fullquery>

 
</queryset>
