<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_template_to_item">      
      <querytext>

        select content_item__register_template(
            :item_id,
            :template_id,
            :context ); 
        
  
      </querytext>
</fullquery>

 
</queryset>
