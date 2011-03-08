<?xml version="1.0"?>
<queryset> 

<fullquery name="content_method::text_entry_filter_sql.count_text_mime_types">
	<querytext>
		select count(*)
		from cr_content_mime_type_map
		where mime_type like ('%text/%')
		 and content_type = :content_type
	</querytext>
</fullquery>

<fullquery name="content_method::get_content_methods.get_methods_1">
	<querytext>
  select
    map.content_method
  from
    cm_content_type_method_map map, cm_content_methods m
  where
    map.content_method = m.content_method
  and
    map.content_type = :content_type
  $text_entry_filter

	</querytext>
</fullquery>

<fullquery name="content_method::get_content_methods.get_methods_2">
	<querytext>

  select
    content_method
  from
    cm_content_methods m
  where 1 = 1
  $text_entry_filter

	</querytext>
</fullquery>


 
<fullquery name="content_method::get_content_method_options.get_methods_1"> 
      <querytext>
      
	  select
	    label, map.content_method
	  from
	    cm_content_methods m, cm_content_type_method_map map
	  where
            m.content_method = map.content_method
	  and
	    map.content_type = :content_type
	  $text_entry_filter
	
      </querytext>
</fullquery>

 
<fullquery name="content_method::get_content_method_options.get_methods_2">
      <querytext>
      
	  select
	    label, content_method
	  from
	    cm_content_methods m
	  where 1 = 1
	  $text_entry_filter
	
      </querytext>
</fullquery>

</queryset>

