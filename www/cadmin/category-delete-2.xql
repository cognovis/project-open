<?xml version="1.0"?>
<queryset>

<fullquery name="order_categories_for_delete">
      <querytext>
      
	select category_id
	from categories
	where tree_id = :tree_id
	and category_id in ([join $category_id ,])
	order by left_ind desc

      </querytext>
</fullquery>

 
</queryset>
