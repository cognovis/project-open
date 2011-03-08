<?xml version="1.0"?>
<queryset>

<fullquery name="delete_arc">      
      <querytext>
      
    delete from wf_arcs
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    place_key = :place_key
    and    direction = :direction

      </querytext>
</fullquery>

 
</queryset>
