<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_content_type">      
      <querytext>

  select 
    case when ot2.supertype = 'acs_object' then '' else ot2.supertype end as parent_type,   
    case when ot2.object_type = 'content_revision' then '' else ot2.object_type end as object_type,
    ot2.pretty_name
  from 
    (select * from acs_object_types where object_type = :content_type) ot1,
    acs_object_types ot2
  where
    ot2.object_type != 'acs_object'
  and 
    ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
  order by ot2.tree_sortkey asc

      </querytext>
</fullquery>

 
<fullquery name="get_attr_types">      
      <querytext>

  select 
    attr.attribute_id, attr.attribute_name, attr.object_type,
    attr.pretty_name as attribute_name_pretty,
    datatype, types.pretty_name as pretty_name,
    coalesce(description_key,'&nbsp;') as description_key, 
    description, widget
  from 
    acs_attributes attr left outer join cm_attribute_widgets w using (attribute_id)
    left outer join acs_attribute_descriptions d using (attribute_name),
    ( select 
        o2.object_type, o2.pretty_name
      from 
        (select * from acs_object_types where object_type = :content_type)  o1,
        acs_object_types o2
      where 
        o2.object_type != 'acs_object'
      and 
        o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
    ) types        
  where 
    attr.object_type = types.object_type
  order by 
    types.object_type, sort_order, attr.attribute_name

      </querytext>
</fullquery>

 
<fullquery name="get_type_templates">      
      <querytext>
      
  select 
    template_id, ttmap.content_type, use_context, is_default, name, 
    content_item__get_path(
      template_id,:root_id) as path,
    (select pretty_name 
       from acs_object_types 
       where object_type = :content_type) as pretty_name
  from 
    cr_type_template_map ttmap, cr_items i 
  where 
    i.item_id = ttmap.template_id
  and 
    ttmap.content_type = :content_type
  order by 
    upper(name)

      </querytext>
</fullquery>

 
</queryset>
