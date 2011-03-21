<?xml version="1.0"?>
<queryset>

<fullquery name="cms_rel::sort_related_item_order.get_related_items">      
      <querytext>
      
            select
              rel_id
            from
              cr_item_rels
            where
              item_id = :item_id
            order by
              order_n, rel_id
        
      </querytext>
</fullquery>


<fullquery name="cms_rel::sort_related_item_order.reorder">      
      <querytext>
  	        update cr_item_rels
                  set order_n = :i
                  where rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="cms_rel::sort_child_item_order.get_child_order">      
      <querytext>
      
            select
              rel_id
            from
              cr_child_rels
            where
              parent_id = :item_id
            order by
              order_n, rel_id
        
      </querytext>
</fullquery>

<fullquery name="cms_rel::sort_child_item_order.reorder">      
      <querytext>
  	        update cr_child_rels
                  set order_n = :i
                  where rel_id = :rel_id
      </querytext>
</fullquery>
 
</queryset>
