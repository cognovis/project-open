<?xml version="1.0"?>
<queryset>

<fullquery name="move_keyword_item">      
      <querytext>
      
       update cr_items set parent_id = $update_value
         where item_id = $item_id
         and exists (
           select 1 from cr_keywords where keyword_id = item_id
         )
      </querytext>
</fullquery>

 
<fullquery name="move_keyword_keyword">      
      <querytext>
      
       update cr_keywords set parent_id = $update_value
         where keyword_id = $item_id
      </querytext>
</fullquery>

 
</queryset>
