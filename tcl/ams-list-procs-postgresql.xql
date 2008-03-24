<?xml version="1.0"?>
<queryset>


<fullquery name="ams::list::get.select_list_info">
  <querytext>
        select *
          from ams_lists
         where list_id = :list_id
  </querytext>
</fullquery>


<fullquery name="ams::list::ams_attribute_ids_not_cached.ams_attribute_ids">
  <querytext>
        select attribute_id
          from ams_list_attribute_map
         where list_id = :list_id
  </querytext>
</fullquery>

<fullquery name="ams::list::copy.get_from_list_data">
  <querytext>
        select pretty_name,
               description,
               description_mime_type
          from ams_lists
         where list_id = :from_id
  </querytext>
</fullquery>

<fullquery name="ams::list::copy.copy_list">
  <querytext>
        insert into ams_list_attribute_map
        (list_id,attribute_id,sort_order,required_p,section_heading)
        ( select :to_id,
                 attribute_id,
                 sort_order,
                 required_p,
                 section_heading
            from ams_list_attribute_map
           where list_id = :from_id )
  </querytext>
</fullquery>

<fullquery name="ams::list::copy.list_has_attributes_mapped">
  <querytext>
        select '1'
          from ams_list_attribute_map
         where list_id = :to_id
         limit 1
  </querytext>
</fullquery>

<fullquery name="ams::list::exists_p.list_exists_p">
  <querytext>
        select '1' 
          from ams_lists
         where package_key = :package_key
           and object_type = :object_type
           and list_name = :list_name
  </querytext>
</fullquery>

<fullquery name="ams::list::get_list_id_not_cached.get_list_id">
  <querytext>
        select list_id
          from ams_lists
         where package_key = :package_key
           and object_type = :object_type
           and list_name = :list_name
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::map.delete_old_entry">
  <querytext>
        delete from ams_list_attribute_map
         where list_id = :list_id
           and ( attribute_id = :attribute_id or sort_order = :sort_order )
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::map.ams_list_attribute_map">
  <querytext>
        select ams_list__attribute_map (
                :list_id,
                :attribute_id,
                :sort_order,
                :required_p,
                :section_heading
        )
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::map.get_highest_sort_order">
  <querytext>
        select sort_order
          from ams_list_attribute_map
         where list_id = :list_id
         order by sort_order desc
         limit 1
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::unmap.ams_list_attribute_unmap">
  <querytext>
        delete from ams_list_attribute_map
         where list_id = :list_id
           and attribute_id = :attribute_id
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::required.ams_list_attribute_required">
  <querytext>
        update ams_list_attribute_map
           set required_p = 't'
         where list_id = :list_id
           and attribute_id = :attribute_id
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::optional.ams_list_attribute_optional">
  <querytext>
        update ams_list_attribute_map
           set required_p = 'f'
         where list_id = :list_id
           and attribute_id = :attribute_id
  </querytext>
</fullquery>

<fullquery name="ams::list::attribute::get_mapped_attributes.get_attributes">
  <querytext>
	select 
		attribute_id 
	from 
		ams_list_attribute_map 
	where 
		list_id = :list_id 
	order by 
		attribute_id
  </querytext>
</fullquery>

</queryset>
