<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select 
    content_item.get_path(item_id) path, item_id 
  from 
    cr_items 
  where item_id = (
    select item_id from cr_revisions where revision_id = :revision_id)
      </querytext>
</fullquery>

 
</queryset>
