<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_item">      
      <querytext>
      
  select 
    coalesce(content_item__get_path(:parent_id,null), '/') as item_path,
    pretty_name as content_type_name
  from
    acs_object_types
  where
    object_type = :content_type

      </querytext>
</fullquery>

 
</queryset>
