<?xml version="1.0"?>
<queryset>

<fullquery name="panel_delete">      
      <querytext>
      
    delete from wf_transition_attribute_map
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    attribute_id = :attribute_id

      </querytext>
</fullquery>

 
</queryset>
