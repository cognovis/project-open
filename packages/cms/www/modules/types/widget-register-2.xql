<?xml version="1.0"?>
<queryset>

<fullquery name="get_attr_info">      
      <querytext>
      
  select
    a.pretty_name as attribute_name_pretty, 
    a.attribute_name,
    t.pretty_name as content_type_pretty,
    a.object_type as content_type
  from
    acs_attributes a, acs_object_types t
  where
    a.object_type = t.object_type
  and
    a.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
<fullquery name="get_params">      
      <querytext>


  select
    f.param_id, param, 
    case when f.is_required = 't' then 't' else w.is_required end as is_required, is_html, 
    coalesce(w.value,f.default_value) as default_value,
    coalesce(w.param_source,'literal') as param_source
  from
    cm_form_widget_params f left outer join
    ( select 
        is_required, param_id, param_source, value
      from 
        cm_attribute_widget_params awp, cm_attribute_widgets aw
      where 
        awp.attribute_id = :attribute_id
      and
        awp.attribute_id = aw.attribute_id
    ) w using (param_id)
  where
    widget = :widget

      </querytext>
</fullquery>

 
</queryset>
