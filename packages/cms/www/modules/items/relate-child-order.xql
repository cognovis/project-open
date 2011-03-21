<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="child_swap_1">      
      <querytext>
      
    update cr_child_rels set order_n = :swap_order where rel_id = :rel_id
  
      </querytext>
</fullquery>

 
<fullquery name="child_swap_2">      
      <querytext>
      
    update cr_child_rels set order_n = :order_n where rel_id = :swap_id
  
      </querytext>
</fullquery>

 
<fullquery name="get_prev_swap_rel">      
      <querytext>
      
    select rel_id, order_n from cr_child_rels r1
    where r1.parent_id = :item_id
    and r1.order_n < :order_n 
    and not exists (select order_n from cr_child_rels r2
                    where r2.parent_id = :item_id
                    and r2.order_n < :order_n
                    and r2.order_n > r1.order_n)
      </querytext>
</fullquery>

 
<fullquery name="get_next_swap_rel">      
      <querytext>
      
    select rel_id, order_n from cr_child_rels r1
    where r1.parent_id = :item_id
    and r1.order_n > :order_n 
    and not exists (select order_n from cr_child_rels r2
                    where r2.parent_id = :item_id
                    and r2.order_n > :order_n
                    and r2.order_n < r1.order_n)
      </querytext>
</fullquery>

 
</queryset>
