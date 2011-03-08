<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unregister">      
      <querytext>

        select cm_form_widget__unregister_attribute_widget (
                        :content_type,
                        :attribute_name
        );
 
      </querytext>
</fullquery>

 
</queryset>
