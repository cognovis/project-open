<?xml version="1.0"?>
<queryset>

<fullquery name="get_tree">      
      <querytext>
      
	    select category_id, parent_id
	    from categories
	    where tree_id = :tree_id
	    order by left_ind
	
      </querytext>
</fullquery>

 
<fullquery name="reset_category_index">      
      <querytext>
      
		update categories
		set left_ind = -left_ind,
		right_ind = -right_ind
		where tree_id = :tree_id
	    
      </querytext>
</fullquery>

 
<fullquery name="update_category_index">      
      <querytext>
      
		    update categories
		    set left_ind = :left_ind,
		    right_ind = :right_ind
		    where category_id = :category_id
		
      </querytext>
</fullquery>

 
</queryset>
