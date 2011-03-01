<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_trees_to_link">
      <querytext>
      
    select tree_id as link_tree_id
    from category_trees
    where acs_permission__permission_p(tree_id,:user_id,'category_tree_write') = 't'

      </querytext>
</fullquery>

 
</queryset>
