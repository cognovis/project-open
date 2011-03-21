<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_revision">      
      <querytext>
      
  select 
    revision_id, title, description, item_id, mime_type, 
    content_revision__get_number( revision_id ) as revision_number,
    (
     select 
       label 
     from 
       cr_mime_types 
     where 
       mime_type = cr_revisions.mime_type
    ) as mime_type_pretty,
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
      
  select content_item__is_publishable( :item_id ) 

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
    ) as content_type,
    content_item__get_path(item_id,null) as path
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
     where object_type = attr.object_type) as object_type,
    coalesce(column_name,attribute_name) as attribute_name,  
    coalesce(attr.table_name,o.table_name) as table_name,
    coalesce(o.id_column,'object_id') as id_column
  from
    acs_attributes attr, 
    (select 
       ot2.object_type, ot2.table_name, ot2.id_column 
     from
       (select * from acs_object_types where object_type = (select 
                        object_type 
                      from 
                        acs_objects
                      where
                        object_id = :revision_id)) ot1,
       acs_object_types ot2
     where 
       ot2.object_type not in ('acs_object','content_revision')
     and 
       ot2.tree_sortkey <= ot1.tree_sortkey
     and 
       ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)) o
  where
    o.object_type = attr.object_type
  order by
    attr.object_type, attr.sort_order

      </querytext>
</fullquery>

<fullquery name="get_content">      
      <querytext>

      select 
        content
      from
        cr_revisions
      where
        revision_id = :revision_id
    
      </querytext>
</fullquery>

 
</queryset>
