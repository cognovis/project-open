<?xml version="1.0"?>
<queryset>

<fullquery name="arcs_delete">      
      <querytext>
      
	delete from wf_arcs
	where  workflow_key = :workflow_key
	and    place_key = :place_key
    
      </querytext>
</fullquery>

 
<fullquery name="place_delete">      
      <querytext>
      
	delete from wf_places
	where  workflow_key = :workflow_key
	and    place_key = :place_key
    
      </querytext>
</fullquery>

 
</queryset>
