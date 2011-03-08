<?xml version="1.0"?>
<queryset>

<fullquery name="num_arcs">      
      <querytext>
       
    select count(*) 
    from   wf_arcs 
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    place_key = :place_key
    and    direction = :direction

      </querytext>
</fullquery>

 
<fullquery name="insert_arc">      
      <querytext>
      
	insert into wf_arcs (workflow_key, transition_key, place_key, direction) 
	values (:workflow_key, :transition_key, :place_key, :direction)
    
      </querytext>
</fullquery>

 
</queryset>
