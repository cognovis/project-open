<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="trees_select">      
      <querytext>
      
    select tree_id as source_tree_id, site_wide_p,
           acs_permission__permission_p(tree_id, :user_id, 'category_tree_read') as has_read_p
    from category_trees
    where tree_id <> :tree_id

      </querytext>
</fullquery>

 
</queryset>
