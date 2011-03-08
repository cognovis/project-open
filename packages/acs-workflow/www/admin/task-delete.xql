<?xml version="1.0"?>
<queryset>

<fullquery name="arcs_delete">      
      <querytext>
      
	delete from wf_arcs
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="transition_attribute_map_delete">      
      <querytext>
      
	delete from wf_transition_attribute_map
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="transition_assignment_map_delete">      
      <querytext>
      
	delete from wf_transition_assignment_map
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_context_assignments_delete">      
      <querytext>
      
	delete from wf_context_assignments
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_context_transition_info_delete">      
      <querytext>
      
	delete from wf_context_transition_info
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="transition_delete">      
      <querytext>
      
	delete from wf_transitions
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
    
      </querytext>
</fullquery>

 
</queryset>
