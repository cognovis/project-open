<?xml version="1.0"?>
<queryset>

<fullquery name="get_mapped_subtree_id">
      <querytext>
      
	select subtree_category_id as category_id
	from category_tree_map
	where tree_id = :tree_id
	and object_id = :object_id

      </querytext>
</fullquery>

 
<fullquery name="get_mapping_parameters">
      <querytext>
      
	    select assign_single_p, require_category_p, widget
	    from category_tree_map
	    where tree_id = :tree_id
	    and object_id = :object_id

      </querytext>
</fullquery>

 
</queryset>
