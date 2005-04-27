<?xml version="1.0"?>
<queryset>

<fullquery name="num_transitions">      
      <querytext>
      
	    select count(*) 
	    from   wf_transitions
	    where  workflow_key = :workflow_key
	    and    transition_name = :transition_name
	
      </querytext>
</fullquery>

 
</queryset>
