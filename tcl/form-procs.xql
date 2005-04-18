<?xml version="1.0"?>
<queryset>

<fullquery name="content::create_form_element.get_content_type">      
	<querytext>
	select content_type from cr_items i, cr_revisions r
	where r.item_id = i.item_id
	and   r.revision_id = :revision_id
	</querytext>

</fullquery>

<partialquery name="content::create_form_element.cfe_attribute_name">
	<querytext>

	$attribute_name

	</querytext>

</partialquery>

<fullquery name="content::create_form_element.get_element_value">      
	<querytext>
	select $what from ${table_name}x where revision_id = :revision_id
	</querytext>
</fullquery>

<partialquery name="content::query_form_metadata.attributes_query_extra_where">
	<querytext>

	 and $extra_where

	</querytext>
</partialquery>

<fullquery name="content::process_revision_form_dml.insert_revision_form">
	<querytext>
              insert into $__last_table (
                [join $__columns ", "]
              ) values (
                [join $__values ", "]
              )"
	</querytext>
</fullquery>

<partialquery name="content::insert_element_data.ied_get_objects_tree_extra_where">
	<querytext>

	 and $extra_where

	</querytext>
</partialquery>

<partialquery name="content::insert_element_data.ied_get_objects_tree_order_by">
	<querytext>

          order by 
            types.inherit_level desc

	</querytext>
</partialquery>

<fullquery name="content::process_insert_statement.process_insert_statement">
	<querytext>
              insert into $__last_table (
                [join $__columns ", "]
              ) values (
                [join $__values ", "]
              )"
	</querytext>
</fullquery>

<fullquery name="content::add_revision.addrev_get_content_type">
	<querytext>
    select object_type as content_type, table_name
    from acs_object_types
    where object_type = (select content_type from cr_items 
                         where item_id = :item_id)
	</querytext>
</fullquery>

<fullquery name="content::upload_content.update_mime_sql">
	<querytext>

      update cr_revisions 
        set mime_type = :mime_type 
        where revision_id = :revision_id

	</querytext>
</fullquery>

<fullquery name="content::add_content_element.get_text_mime_types">
	<querytext>

	    select
	      label, map.mime_type as value
	    from
	      cr_mime_types types, cr_content_mime_type_map map
	    where
	      types.mime_type = map.mime_type
	    and
	      map.content_type = :content_type
	    and
	      lower(types.mime_type) like ('text/%')
	    order by
	      label

	</querytext>
</fullquery>

<fullquery name="content::add_child_relation_element.get_parent_type">
	<querytext>

    select content_type from cr_items 
    where item_id = :parent_id

	</querytext>
</fullquery>

<fullquery name="content::get_widget_param_value.set_content_values">
	<querytext>

	$param(value)

	</querytext>
</fullquery>

<fullquery name="content::get_type_attribute_params.gtap_get_attribute_data">
	<querytext>

    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext x
    where
      object_type in ( [join $in_list ","] )

	</querytext>
</fullquery>

<fullquery name="content::get_attribute_params.gap_get_attribute_data">
	<querytext>

    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext
    where
      object_type = :content_type
    and
      attribute_name = :attribute_name

	</querytext>
</fullquery>

<fullquery name="content::set_attribute_values.get_previous_version_values">
	<querytext>

    select 
      [join $columns ", "] 
    from 
      [get_type_info $content_type table_name]x
    where 
      revision_id = :revision_id

	</querytext>
</fullquery>

<fullquery name="content::get_default_content_method.count_mime_type">
	<querytext>

	select count(*) from cr_content_mime_type_map
	where content_type = :content_type and mime_type like 'text/%'

	</querytext>
</fullquery>

<fullquery name="content::get_type_info.get_type_info_1">
	<querytext>

      select 
        $ref
      from 
        acs_object_types 
      where 
        object_type = :object_type

	</querytext>
</fullquery>

<fullquery name="content::get_type_info.get_type_info_2">
	<querytext>

      select 
        [join $args ","]
      from 
        acs_object_types 
      where 
        object_type = :object_type

	</querytext>
</fullquery>


<fullquery name="content::copy_content.cc_get_mime_type">
	<querytext>

      select mime_type from cr_revisions where revision_id = :revision_id_src

	</querytext>
</fullquery>

<fullquery name="content::copy_content.cc_update_cr_revisions">
	<querytext>

           update cr_revisions
           set mime_type = :mime_type
           where revision_id = :revision_id_dest

	</querytext>
</fullquery>

<fullquery name="content::validate_name.vn_same_name_count1">
	<querytext>

	  select count(1)
	  from cr_items
          where name = :name

	</querytext>
</fullquery>

<fullquery name="content::validate_name.vn_same_name_count2">
	<querytext>

	  select count(1)
          from cr_items
          where name = :name
            and parent_id = :parent_id

	</querytext>
</fullquery>

</queryset>
