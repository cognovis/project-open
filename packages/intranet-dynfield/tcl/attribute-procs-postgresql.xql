<?xml version="1.0"?>

<queryset>
   <rdbms>
	<type>postgresql</type>
	<version>7.1</version>
   </rdbms>


<fullquery name="delete_xt.select_attr_info">
	<querytext>
	
	select	a.object_type, 
		a.attribute_name, 
		case when a.storage = 'type_specific' 
		then t.table_name else a.table_name end as table_name,
		nvl(a.column_name, a.attribute_name) as column_name
	from	acs_attributes a, 
		acs_object_types t
	where
		a.attribute_id = :attribute_id
		and t.object_type = a.object_type
	
	</querytext>
</fullquery>

<fullquery name="attribute::name.get_attribute_name">
  <querytext>
        select attribute_name from acs_attributes where attribute_id = :attribute_id
  </querytext>
</fullquery>

<fullquery name="attribute::delete_xt.drop_attribute">
<querytext>

    select im_dynfield_attribute__del(:im_dynfield_attribute_id); 

</querytext>
</fullquery>

</queryset>
