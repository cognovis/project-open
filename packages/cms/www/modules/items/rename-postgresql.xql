<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rename_item">      
      <querytext>

        select content_item__edit_name (
            :item_id, 
            :name 
         ); 
    
      </querytext>
</fullquery>

 
</queryset>
