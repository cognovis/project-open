<?xml version="1.0"?>
<queryset>

<fullquery name="get_linked_categories">
      <querytext>
      
    select (case when l.from_category_id = :category_id then 'f' else 'r' end) as direction,
           c.category_id as linked_category_id
    from category_links l, categories c
    where c.tree_id = :link_tree_id
    and ((l.from_category_id = :category_id
          and l.to_category_id = c.category_id)
    or (l.from_category_id = c.category_id
        and l.to_category_id = :category_id))

      </querytext>
</fullquery>

 
</queryset>
