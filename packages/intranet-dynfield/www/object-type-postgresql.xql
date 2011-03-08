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
	lower(aa.datatype) as attribute_data_type,
	lower(c.data_type) as table_data_type,
        fa.attribute_id as im_dynfield_attribute_id,
        fa.widget_name,
	fa.also_hard_coded_p,
	w.widget_id,
	w.widget,
	w.parameters,
	la.pos_x, pos_y, size_x, size_y,
	la.div_class,
	la.label_style
    from 
	acs_attributes aa
	RIGHT OUTER join 
		im_dynfield_attributes fa 
		ON (aa.attribute_id = fa.acs_attribute_id)
	LEFT OUTER join
		(select	* from im_dynfield_layout where page_url = 'default') la
		ON (fa.attribute_id = la.attribute_id)
	LEFT OUTER join
		user_tab_columns c
		ON (c.table_name = upper(aa.table_name) and c.column_name = upper(aa.attribute_name)),
	im_dynfield_widgets w
    where 
	aa.object_type = :object_type
	and fa.widget_name = w.widget_name
    order by
	la.pos_y, la.pos_x, aa.attribute_name

  </querytext>
</fullquery>

</queryset>
