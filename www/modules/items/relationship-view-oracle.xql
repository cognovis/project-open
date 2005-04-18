<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_rel_info">      
      <querytext>
      
  select
    t.pretty_name as type_name, t.object_type, 
    r.item_id, r.related_object_id,\
    content_item.get_title(i.item_id) as item_title,
    acs_object.name(r.related_object_id) as related_title,
    content_item.is_subclass(o2.object_type, 'content_item') as is_item,
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
    acs_attributes attr,
    (select 
        object_type, table_name, id_column, pretty_name,
        level as inherit_level
      from 
        acs_object_types
      where 
        object_type not in ('acs_object', 'cr_item_rel')
      connect by 
        prior supertype = object_type
      start with 
        object_type = :object_type) types
  where
    attr.object_type (+) = types.object_type
  order by
    inherit_level desc, attr.pretty_name
  
      </querytext>
</fullquery>

 
</queryset>
