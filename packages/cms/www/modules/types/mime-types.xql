<?xml version="1.0"?>
<queryset>

<fullquery name="get_module_id">      
      <querytext>
      
  select module_id from cm_modules where key = 'types'

      </querytext>
</fullquery>

 
<fullquery name="get_name">      
      <querytext>
      
  select
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type

      </querytext>
</fullquery>

 
<fullquery name="get_unreg_mime_types">      
      <querytext>
      
  select
    label, mime_type
  from 
    cr_mime_types
  where
    not exists ( select 1
                 from 
                   cr_content_mime_type_map
                 where
                   mime_type = cr_mime_types.mime_type
                 and
                   content_type = :content_type )
  order by
    label

      </querytext>
</fullquery>

 
<fullquery name="get_reg_mime_types">      
      <querytext>
      
  select 
    label, m.mime_type
  from
    cr_mime_types m, cr_content_mime_type_map map
  where
    m.mime_type = map.mime_type
  and
    map.content_type = :content_type
  order by
    label

      </querytext>
</fullquery>

 
</queryset>
