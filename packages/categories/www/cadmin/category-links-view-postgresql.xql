<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_category_links">
      <querytext>
      
    select c.category_id as linked_category_id, c.tree_id as linked_tree_id, l.link_id,
           (case when l.from_category_id = :category_id then 'f' else 'r' end) as direction,
           acs_permission__permission_p(c.tree_id,:user_id,'category_tree_write') as write_p
    from category_links l, categories c
    where (l.from_category_id = :category_id
	   and l.to_category_id = c.category_id)
    or (l.from_category_id = c.category_id
	and l.to_category_id = :category_id)

      </querytext>
</fullquery>

 
</queryset>
