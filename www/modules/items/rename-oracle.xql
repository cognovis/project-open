<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rename_item">      
      <querytext>
      
    begin 
    content_item.edit_name (
        item_id => :item_id, 
        name    => :name 
    ); 
    end;
      </querytext>
</fullquery>

 
</queryset>
