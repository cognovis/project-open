<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select
    content_item.get_revision_count(x.item_id) revision_count, 
    content_revision.get_number(:revision_id) revision_number, 
    content_item.get_live_revision(x.item_id) live_revision, 
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
    types.pretty_name object_label, 
    types.table_name, 
    types.id_column, 
    attr.attribute_name, 
    attr.pretty_name attribute_label
  from 
    acs_attributes attr,
    ( select 
        object_type, pretty_name, table_name, id_column, 
        level as inherit_level
      from 
        acs_object_types
      where 
        object_type ^= 'acs_object'
      connect by 
        prior supertype = object_type
      start with 
        object_type = :content_type) types        
  where 
    attr.object_type = types.object_type
  order by 
    types.inherit_level desc, attr.sort_order
      </querytext>
</fullquery>

 
</queryset>
