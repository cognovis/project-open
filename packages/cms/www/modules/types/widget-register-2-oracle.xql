<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_params">      
      <querytext>
      
  select
    f.param_id, param, 
    case when f.is_required = 't' then 't' else w.is_required end is_required, is_html, 
    nvl(w.value,f.default_value) default_value,
    nvl(w.param_source,'literal') param_source
  from
    cm_form_widget_params f, 
    ( select 
        is_required, param_id, param_source, value
      from 
        cm_attribute_widget_params awp, cm_attribute_widgets aw
      where 
        awp.attribute_id = :attribute_id
      and
        awp.attribute_id = aw.attribute_id
    ) w
  where
    widget = :widget
  and
    f.param_id = w.param_id (+)

      </querytext>
</fullquery>

 
</queryset>
