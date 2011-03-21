<?xml version="1.0"?>
<queryset>

<fullquery name="get_mapped_trees">      
      <querytext>
      
         select t.tree_id, t.site_wide_p, m.subtree_category_id,
                m.assign_single_p, m.require_category_p, m.widget
           from category_trees t, category_tree_map m
          where m.object_id = :object_id
            and m.tree_id = t.tree_id
       order by t.tree_id

      </querytext>
</fullquery>

 
</queryset>
