<?xml version="1.0"?>
<queryset>

<fullquery name="get_list">      
      <querytext>
      
	  select
	    parent_id
          from
            cr_resolved_items
          where
            resolved_id = :del_item_id
	
      </querytext>
</fullquery>

 
</queryset>
