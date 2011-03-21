<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select 
    content_item__get_path(item_id,null) as path, item_id 
  from 
    cr_items 
  where item_id = (
    select item_id from cr_revisions where revision_id = :revision_id)

      </querytext>
</fullquery>

 
</queryset>
