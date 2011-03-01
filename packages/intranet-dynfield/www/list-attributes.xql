<?xml version="1.0"?>
<queryset>

<fullquery name="get_default_list">
    <querytext>
	select 
		list_id 
	from 
		ams_lists 
	where 
		object_type = :object_type 
		and list_name = :default_list_name
    </querytext>
</fullquery>

<fullquery name="get_attributes_list">
    <querytext>
	select 
		m.attribute_id 
	from 
		ams_list_attribute_map m,
		ams_lists l
	where 
		l.object_type = :object_type
		and l.list_name like :name_first_part||'__%'
		and l.list_id = m.list_id
	order by
		m.attribute_id
    </querytext>
</fullquery>

<fullquery name="get_default_attributes_list">
    <querytext>
	select 
		attribute_id 
	from 
		ams_list_attribute_map 
	where 
		list_id = :default_list_id 
	order by 
		attribute_id
    </querytext>
</fullquery>

</queryset>