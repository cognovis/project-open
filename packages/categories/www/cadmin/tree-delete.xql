<?xml version="1.0"?>
<queryset>

<fullquery name="get_category_in_use">      
      <querytext>
      
    select category_id
    from categories c
    where c.tree_id = :tree_id
    and exists (select 1 from category_object_map
                 where category_id = c.category_id)

      </querytext>
</fullquery>

 
</queryset>
