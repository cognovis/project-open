<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_item">      
      <querytext>
      
  select 
    nvl(content_item.get_path(:parent_id), '/') as item_path,
    pretty_name as content_type_name
  from
    acs_object_types
  where
    object_type = :content_type

      </querytext>
</fullquery>

 
</queryset>
