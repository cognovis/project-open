<?xml version="1.0"?>
<queryset>

<fullquery name="second_template_p">      
      <querytext>
      
  select count(1) from cr_item_template_map
    where use_context = :context
    and item_id = :item_id
      </querytext>
</fullquery>

 
</queryset>
