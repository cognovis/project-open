<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select distinct
    content_item__get_revision_count(x.item_id) as revision_count, 
    content_revision__get_number(:revision_id) as revision_number, 
    content_item__get_live_revision(x.item_id) as live_revision, 
    x.*
  from
    $type_info(table_name)x x
  where
    object_id = :revision_id
      </querytext>
</fullquery>

 
<fullquery name="get_attributes">      
      <querytext>

  select 
    types.pretty_name as object_label, 
    types.table_name, 
    types.id_column, 
    attr.attribute_name, 
    attr.pretty_name as attribute_label
  from 
    acs_attributes attr,
    ( select 
        ot2.object_type, ot2.pretty_name, ot2.table_name, ot2.id_column, 
        tree_level(ot2.tree_sortkey) as inherit_level
      from 
        (select * from acs_object_types where object_type = :content_type) ot1, 
        acs_object_types ot2
      where 
        ot2.object_type != 'acs_object'
      and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)) types        
  where 
    attr.object_type = types.object_type
  order by 
    types.inherit_level desc, attr.sort_order
      </querytext>
</fullquery>

 
</queryset>
