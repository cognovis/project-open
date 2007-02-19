<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_unmapped_trees">      
      <querytext>
      
    select tree_id, site_wide_p,
          acs_permission.permission_p(tree_id, :user_id, 'category_tree_read') has_read_permission  
     from category_trees t
    where not exists (select 1 from category_tree_map m
                       where m.object_id = :object_id
                         and m.tree_id = t.tree_id)
    order by t.tree_id

      </querytext>
</fullquery>

 
</queryset>
