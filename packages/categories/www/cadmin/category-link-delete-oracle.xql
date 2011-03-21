<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="check_category_links">
      <querytext>
      
    select c.category_id as linked_category_id, c.tree_id as linked_tree_id,
           (case when l.from_category_id = :category_id then 'f' else 'r' end) as direction,
           acs_permission.permission_p(c.tree_id,:user_id,'category_tree_write') as write_p,
           l.link_id
    from category_links l, categories c
    where l.link_id in ([join $link_id ,])
    and ((l.from_category_id = :category_id
	  and l.to_category_id = c.category_id)
	 or (l.from_category_id = c.category_id
	     and l.to_category_id = :category_id))

      </querytext>
</fullquery>

 
</queryset>
