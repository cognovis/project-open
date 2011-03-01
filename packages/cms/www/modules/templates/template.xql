<?xml version="1.0"?>
<queryset>

<fullquery name="get_types">      
      <querytext>
      
  select
    pretty_name, content_type, use_context
  from
    acs_object_types types, cr_type_template_map map
  where
    map.template_id = :template_id
  and
    types.object_type = map.content_type
  order by
    types.pretty_name
      </querytext>
</fullquery>

 
</queryset>
