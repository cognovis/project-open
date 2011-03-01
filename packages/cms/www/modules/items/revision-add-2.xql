<?xml version="1.0"?>
<queryset>

<fullquery name="get_one_item">      
      <querytext>
      
  select 
    content_type, name
  from
    cr_items
  where
   item_id = :item_id

      </querytext>
</fullquery>

 
</queryset>
