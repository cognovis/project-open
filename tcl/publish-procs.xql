<?xml version="1.0"?>
<queryset>

<fullquery name="publish::set_publish_status.sps_update_cr_items">      
      <querytext>
      update cr_items set publish_status = :new_status
                              where item_id = :item_id
      </querytext>
</fullquery>

 
</queryset>
