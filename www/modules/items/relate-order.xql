<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="relate_swap_1">      
      <querytext>
      
      update $rel_table 
        set order_n = :swap_order 
        where rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="relate_swap_2">      
      <querytext>
      
      update $rel_table 
        set order_n = :order_n 
        where rel_id = :swap_id
      </querytext>
</fullquery>

 
<fullquery name="get_item_id">      
      <querytext>
      
  select 
    $rel_parent_column
  from 
    $rel_table
  where 
    rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="get_order">      
      <querytext>
      
  select
    order_n
  from
    $rel_table
  where
    rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="get_prev_swap_rel">      
      <querytext>
      
      select 
        rel_id, order_n 
      from 
        $rel_table
      where 
        $rel_parent_column = :item_id
      and 
        order_n = :order_n - 1
      </querytext>
</fullquery>

 
<fullquery name="get_next_swap_rel">      
      <querytext>
      
      select 
        rel_id, order_n 
      from 
        $rel_table
      where 
        $rel_parent_column = :item_id
      and 
        order_n = :order_n + 1
      </querytext>
</fullquery>

 
</queryset>
