<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_content_type">      
      <querytext>
      
  select
    content_item.get_content_type( :item_id )
  from
    dual

      </querytext>
</fullquery>

 
</queryset>
