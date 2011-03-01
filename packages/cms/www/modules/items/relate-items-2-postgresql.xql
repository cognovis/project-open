<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="relate">      
      <querytext>


        select content_item__relate (
          :item_id,
          :related_id,
          :relation_tag,
          :order_n,
          :relation_type
      );
   
      </querytext>
</fullquery>

 
<fullquery name="get_title">      
      <querytext>
      
  select content_item__get_title(:item_id, 'f') 
      </querytext>
</fullquery>

 
</queryset>
