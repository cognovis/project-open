<?xml version="1.0"?>

<queryset>
   <rdbms>
	<type>postgresql</type>
	<version>7.2</version>
  </rdbms>

<fullquery name="attributes_query">
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
	acs_attributes aa
	right outer join 
		im_dynfield_attributes fa 
		on (aa.attribute_id = fa.acs_attribute_id),
	im_dynfield_widgets w
    where 
	aa.object_type = :object_type
	and fa.widget_name = w.widget_name

  </querytext>
</fullquery>


<fullquery name="objects_query">
  <querytext>

    select
	$id_column as object_id,
	acs_object__name($id_column) as object_name
    from
	$table_name

  </querytext>
</fullquery>

</queryset>
