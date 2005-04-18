<?xml version="1.0"?>
<queryset>

<fullquery name="get_form_widgets"> 
      <querytext>
 select
    widget, widget
  from
    cm_form_widgets    
      </querytext>
</fullquery>

<fullquery name="check_registered">      
      <querytext>
      
      select 1
      from
        cm_attribute_widgets
      where
        attribute_id = :attribute_id
      and
        widget = :widget
    
      </querytext>
</fullquery>

<fullquery name="get_reg_widget">
      <querytext>
      select
        widget as registered_widget, is_required
      from
        cm_attribute_widgets
      where
        attribute_id = :attribute_id
      </querytext>
</fullquery>

<fullquery name="get_attr_info">      
      <querytext>
      select
        a.pretty_name as attribute_name_pretty, 
        t.pretty_name as content_type_pretty,
        t.object_type as content_type,
        a.attribute_name
      from
        acs_attributes a, acs_object_types t
      where
        a.object_type = t.object_type
      and
        a.attribute_id = :attribute_id
      </querytext>
</fullquery>

</queryset>
