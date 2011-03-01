<?xml version="1.0"?>
<queryset>

<fullquery name="assignment_delete">      
      <querytext>
      
	delete from wf_transition_role_assign_map
	 where workflow_key = :workflow_key
  	   and transition_key = :transition_key
	   and assign_role_key = :role_key
    
      </querytext>
</fullquery>

 
</queryset>
