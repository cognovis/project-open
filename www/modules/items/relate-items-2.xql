<?xml version="1.0"?>
<queryset>

<fullquery name="get_order">      
      <querytext>
      
        select 
	  coalesce(max(order_n) + 1, 1) 
	from 
	  cr_item_rels
	where 
	  item_id = :item_id
        
      </querytext>
</fullquery>

 
</queryset>
