<?xml version="1.0"?>

<queryset>
   <rdbms>
	<type>oracle</type>
	<version>8.0</version>
  </rdbms>

<fullquery name="attribute_query">
  <querytext>

    select 
	aa.attribute_name,
        aa.pretty_name,
        aa.pretty_plural,
	aa.table_name,
        aa.attribute_id as acs_attribute_id,
        fa.attribute_id as im_dynfield_attribute_id,
        fa.widget_name,
	w.widget_id,
	w.widget,
	w.parameters
    from 
	acs_attributes aa, 
	im_dynfield_attributes fa,
	im_dynfield_widgets w
    where 
	aa.object_type = :object_type
	and aa.attribute_id = fa.acs_attribute_id(+)
	and fa.widget_name = w.widget_name


  </querytext>
</fullquery>

</queryset>
