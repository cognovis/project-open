<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_content_type">      
      <querytext>
      
  select
    content_item__get_content_type( :item_id )
  from
    dual

      </querytext>
</fullquery>

 
</queryset>
