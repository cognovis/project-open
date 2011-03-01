<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_unmapped_trees">      
      <querytext>
      
    select tree_id, site_wide_p,
          acs_permission__permission_p(tree_id, :user_id, 'category_tree_read') as has_read_permission  
     from category_trees t
    where not exists (select 1 from category_tree_map m
                       where m.object_id = :object_id
                         and m.tree_id = t.tree_id)
    order by t.tree_id

      </querytext>
</fullquery>

 
</queryset>
