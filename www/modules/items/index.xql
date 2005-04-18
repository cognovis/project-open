<?xml version="1.0"?>
<queryset>

<fullquery name="get_info">      
      <querytext>
      
  select 
    content_type, latest_revision
  from 
    cr_items 
  where 
   item_id = :item_id
      </querytext>
</fullquery>

 
</queryset>
