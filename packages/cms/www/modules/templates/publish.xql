<?xml version="1.0"?>
<queryset>

<fullquery name="update_items">      
      <querytext>
      update cr_items set live_revision = :revision_id
                where item_id = :template_id
      </querytext>
</fullquery>

 
</queryset>
