<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="get_item_id">      
      <querytext>
      
  select item_id from cr_item_rels where rel_id = :rel_id
      </querytext>
</fullquery>

 
</queryset>
