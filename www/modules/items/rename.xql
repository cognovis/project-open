<?xml version="1.0"?>
<queryset>

<fullquery name="get_item_name">      
      <querytext>
      
  select 
    name
  from 
    cr_items
  where 
    item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_parent_id">      
      <querytext>
      
    select
      parent_id
    from
      cr_items
    where
      item_id = :item_id
      </querytext>
</fullquery>

 
</queryset>
