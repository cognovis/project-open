<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_trees_to_link">
      <querytext>
      
    select tree_id as link_tree_id
    from category_trees
    where acs_permission.permission_p(tree_id,:user_id,'category_tree_write') = 't'

      </querytext>
</fullquery>

 
</queryset>
