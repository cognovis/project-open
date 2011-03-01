<?xml version="1.0"?>
<queryset>

<fullquery name="get_outstanding">      
      <querytext>
      
      select
        distinct param
      from
        cm_form_widget_params f
      where
        is_required = 't'
      and
        widget = :widget
      and
        not exists (
          select 1
          from
            cm_attribute_widget_params
          where
            attribute_id = :attribute_id
          and
            param_id = f.param_id )
    
      </querytext>
</fullquery>

 
<fullquery name="get_name">      
      <querytext>
      
      select
        pretty_name, attribute_name, object_type
      from
        acs_attributes
      where
        attribute_id = :attribute_id
    
      </querytext>
</fullquery>

 
</queryset>
