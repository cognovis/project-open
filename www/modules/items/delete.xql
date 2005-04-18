<?xml version="1.0"?>
<queryset>

<fullquery name="flush">      
      <querytext>
      
  select
    parent_id
  from
    cr_resolved_items
  where
    resolved_id = :item_id

      </querytext>
</fullquery>

 
</queryset>
