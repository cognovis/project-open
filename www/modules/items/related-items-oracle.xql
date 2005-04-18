<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_related">      
      <querytext>

  select
    r.rel_id,
    r.related_object_id item_id,
    t.pretty_name as type_name,
    NVL(r.relation_tag, '-') as tag,
    trim(NVL(content_item.get_title(r.related_object_id), i.name)) title,
    ot.pretty_name as content_type
  from
    cr_item_rels r, acs_objects o, acs_object_types t,
    cr_items i, acs_object_types ot
  where
    r.item_id = :item_id
  and
    o.object_id = r.rel_id
  and
    t.object_type = o.object_type
  and 
    i.item_id = r.related_object_id
  and
    ot.object_type = i.content_type
  order by 
    order_n, title

      </querytext>
</fullquery>


</queryset>
