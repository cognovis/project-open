<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="item_delete">      
      <querytext>
      
  begin 
    content_item.del(
      item_id => :item_id
    ); 
  end;
      </querytext>
</fullquery>

 
</queryset>
