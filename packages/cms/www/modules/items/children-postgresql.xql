<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_child_types">      
      <querytext>

  select
    distinct t.pretty_name, c.child_type
  from
    acs_object_types t, cr_type_children c
  where
    c.parent_type = content_item__get_content_type(:item_id)
  and
    c.child_type = t.object_type      

      </querytext>
</fullquery>

<fullquery name="get_children">      
      <querytext>

  select
    r.rel_id,
    r.child_id as item_id,
    t.pretty_name as type_name,
    coalesce(r.relation_tag, '-') as tag,
    trim(coalesce(content_item__get_title(r.child_id,'f'), i.name)) as title,
    ot.pretty_name as content_type
  from
    cr_child_rels r, acs_objects o, acs_object_types t,
    cr_items i, acs_object_types ot
  where
    r.parent_id = :item_id
  and
    o.object_id = r.rel_id
  and
    t.object_type = o.object_type
  and 
    i.item_id = r.child_id
  and
    ot.object_type = i.content_type
  order by 
    order_n, title

      </querytext>
</fullquery>
 
</queryset>
