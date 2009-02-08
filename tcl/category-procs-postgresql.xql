<?xml version="1.0"?>
<queryset>

<fullquery name="contacts::categories::get_selects.get_categories">
  <querytext>
        SELECT
	t.name as cat_name,
	t.category_id as cat_id,
	tm.tree_id,
	tt.name as tree_name
	FROM
	category_tree_map tm,
	categories c, 
	category_translations t,
	category_tree_translations tt
	WHERE
	c.tree_id      = tm.tree_id and 
	c.category_id  = t.category_id and 
	tm.object_id   = :package_id and
	tm.tree_id = tt.tree_id and
	c.deprecated_p = 'f'
	ORDER BY
	tt.name,
	t.name
  </querytext>
</fullquery>


</queryset>
