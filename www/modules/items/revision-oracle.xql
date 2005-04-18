<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_revision">      
      <querytext>
      
  select 
    revision_id, title, description, item_id, mime_type, 
    content_revision.get_number( revision_id ) revision_number,
    (
     select 
       label 
     from 
       cr_mime_types 
     where 
       mime_type = cr_revisions.mime_type
    ) mime_type_pretty,
    to_char(publish_date,'Month DD, YYYY') as publish_date_pretty,
    content_length as content_size
  from 
    cr_revisions
  where 
    revision_id = :revision_id

      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
  select content_item.is_publishable( :item_id ) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_one_item">      
      <querytext>
      
  select 
    name, locale, live_revision as live_revision_id,
    (
      select 
        pretty_name
      from 
        acs_object_types
      where 
        object_type = cr_items.content_type
    ) content_type,
    content_item.get_path(item_id) as path
  from 
    cr_items
  where 
    item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_meta_attrs">      
      <querytext>
      
  select 
    attribute_id, pretty_name, 
    (select pretty_name from acs_object_types
     where object_type = attr.object_type) object_type,
    nvl(column_name,attribute_name) attribute_name,  
    nvl(attr.table_name,o.table_name) table_name,
    nvl(o.id_column,'object_id') id_column
  from
    acs_attributes attr, 
    (select 
       object_type, table_name, id_column 
     from
       acs_object_types
     where 
       object_type not in ('acs_object','content_revision')
     connect by
       prior supertype = object_type
     start with
       object_type = (select 
                        object_type 
                      from 
                        acs_objects
                      where
                        object_id = :revision_id) ) o
  where
    o.object_type = attr.object_type
  order by
    attr.object_type, attr.sort_order

      </querytext>
</fullquery>

 
<fullquery name="get_content">      
      <querytext>

      select 
        blob_to_string(content)
      from
        cr_revisions
      where
        revision_id = :revision_id
    
      </querytext>
</fullquery>

 
</queryset>
