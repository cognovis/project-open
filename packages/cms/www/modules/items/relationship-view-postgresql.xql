<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_rel_info">      
      <querytext>
      
  select
    t.pretty_name as type_name, t.object_type, 
    r.item_id, r.related_object_id,
    content_item__get_title(i.item_id,'f') as item_title,
    acs_object__name(r.related_object_id) as related_title,
    content_item__is_subclass(o2.object_type, 'content_item') as is_item,
    r.relation_tag, r.order_n
  from
    acs_objects o, acs_object_types t, 
    cr_item_rels r, cr_items i, acs_objects o2
  where
    o.object_type = t.object_type
  and
    o.object_id = :rel_id
  and
    r.rel_id = :rel_id
  and 
    i.item_id = r.item_id
  and 
    o2.object_id = r.related_object_id

      </querytext>
</fullquery>

 
<fullquery name="get_rel_attrs">      
      <querytext>
         
  select 
    types.table_name, types.id_column, attr.attribute_name,
    attr.pretty_name as attribute_label, attr.datatype,
    types.pretty_name as type_name
  from 
    acs_attributes attr right outer join 
    (select 
        ot2.object_type, ot2.table_name, ot2.id_column, ot2.pretty_name,
        tree_level(ot2.tree_sortkey) as inherit_level
      from 
        (select * from acs_object_types where object_type = :object_type) ot1,
        acs_object_types ot2
      where 
        ot2.object_type not in ('acs_object', 'cr_item_rel')
      and
        ot2.tree_sortkey <= ot2.tree_sortkey
      and 
        ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)) types 
    using (object_type)
  order by
    inherit_level desc, attr.pretty_name
  
      </querytext>
</fullquery>

 
</queryset>
