<?xml version="1.0"?>
<queryset>

<fullquery name="arc_update">      
      <querytext>
      
    update wf_arcs
    set    guard_callback = :guard_callback,
           guard_custom_arg = :guard_custom_arg,
           guard_description = :guard_description
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    place_key = :place_key
    and    direction = :direction

      </querytext>
</fullquery>

 
</queryset>
