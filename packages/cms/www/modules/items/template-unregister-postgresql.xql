<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="template_unregister">      
      <querytext>

        select content_item__unregister_template(
             :item_id, 
             :template_id, 
             :context ); 
         
      </querytext>
</fullquery>

 
</queryset>
