<?xml version="1.0"?>
<queryset>

<fullquery name="transition_update">      
      <querytext>
      
	    update wf_transitions
	    set    transition_name = :transition_name,
		   trigger_type = :trigger_type,
		   role_key = :role_key
	    where  workflow_key = :workflow_key
	    and    transition_key = :transition_key
	
      </querytext>
</fullquery>

 
<fullquery name="transition_update">      
      <querytext>
      
	    update wf_transitions
	    set    transition_name = :transition_name,
		   trigger_type = :trigger_type,
		   role_key = :role_key
	    where  workflow_key = :workflow_key
	    and    transition_key = :transition_key
	
      </querytext>
</fullquery>

 
<fullquery name="num_rows">      
      <querytext>
      select count(*) from wf_context_transition_info where workflow_key = :workflow_key and transition_key = :transition_key and context_key = 'default'
      </querytext>
</fullquery>

 
<fullquery name="insert_estimated_minmutes">      
      <querytext>
      
		insert into wf_context_transition_info
		(workflow_key, transition_key, context_key, estimated_minutes, instructions)
		values (:workflow_key, :transition_key, 'default', :estimated_minutes, :instructions)
	    
      </querytext>
</fullquery>

 
<fullquery name="update_estimated_minutes">      
      <querytext>
      
		update wf_context_transition_info 
		   set estimated_minutes = :estimated_minutes,
		       instructions = :instructions
		 where workflow_key = :workflow_key  
		   and transition_key = :transition_key 
		   and context_key = 'default'
	    
      </querytext>
</fullquery>

 
</queryset>
