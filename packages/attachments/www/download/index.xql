<?xml version="1.0"?>
<queryset>
  
  <fullquery name="select_version_id">      
    <querytext>
      select live_revision
      from cr_items, attachments
      where cr_items.item_id = attachments.item_id
      and attachments.object_id = :object_id
      and attachments.item_id = :attachment_id
    </querytext>
  </fullquery>
   
</queryset>
