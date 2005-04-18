<?xml version="1.0"?>
<queryset>

<fullquery name="get_methods">      
      <querytext>
      
  select
    m.content_method, label, is_default, description
  from
    cm_content_type_method_map map, cm_content_methods m
  where
    m.content_method = map.content_method
  and
    map.content_type = :content_type
  order by
    is_default desc, label

      </querytext>
</fullquery>

 
<fullquery name="check_status">      
      <querytext>
      
  select
    count( mime_type )
  from
    cr_content_mime_type_map
  where
    mime_type like ('%text/%')
  and
    content_type = :content_type

      </querytext>
</fullquery>

 
<fullquery name="get_unregistered_methods">      
      <querytext>
      
  select
    label, m.content_method
  from
    cm_content_methods m
  where
    not exists ( 
      select 1
      from
        cm_content_type_method_map
      where
        content_method = m.content_method
      and
        content_type = :content_type )
  $text_entry_filter_sql
  order by 
    label

      </querytext>
</fullquery>

 
</queryset>
