<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rename_folder">      
      <querytext>

        select content_folder__edit_name (
        :item_id, 
        :name, 
        :label, 
        :description
    ); 
    
      </querytext>
</fullquery>

 
</queryset>
