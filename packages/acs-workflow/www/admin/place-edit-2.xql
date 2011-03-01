<?xml version="1.0"?>
<queryset>

<fullquery name="place_update">      
      <querytext>
      
    update wf_places
    set    place_name = :place_name,
           sort_order = :sort_order
    where  workflow_key = :workflow_key
    and    place_key = :place_key

      </querytext>
</fullquery>

 
</queryset>
