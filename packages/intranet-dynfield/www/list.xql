<?xml version="1.0"?>
<queryset>

<fullquery name="get_unmapped_attributes">
    <querytext>
	select 
		ida.attribute_id,
               	widget_name as widget,
               	attribute_name,
               	pretty_name,
               	object_type
      	from 
		im_dynfield_attributes ida, acs_attributes aa
        where 
        ida.acs_attribute_id = aa.attribute_id 
        and	ida.attribute_id not in 
				( 
				select 
					attribute_id
				from 
					im_dynfield_type_attribute_map 
				where 
					object_type_id = :list_id 
				)
           	and object_type in ([ams::object_parents -sql -object_type $object_type])
	order by attribute_name
    </querytext>
</fullquery>

</queryset>