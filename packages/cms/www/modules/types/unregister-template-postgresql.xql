<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unregister_template">      
      <querytext>


        select content_type__unregister_template(
                :content_type,
                :template_id,
                :context );

      </querytext>
</fullquery>

 
</queryset>
