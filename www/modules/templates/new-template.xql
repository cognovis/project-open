<?xml version="1.0"?>

<queryset>

<fullquery name="get_mime_types">      
      <querytext>

  select label, m.mime_type from cr_mime_types m, cr_content_mime_type_map t
  where t.content_type = 'content_template' and t.mime_type = m.mime_type

      </querytext>
</fullquery>
 
</queryset>
