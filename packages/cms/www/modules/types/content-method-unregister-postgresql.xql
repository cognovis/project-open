<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content_method_unregister">      
      <querytext>

        select content_method__remove_method (
                :content_type,
                :content_method
        );

      </querytext>
</fullquery>

 
</queryset>
