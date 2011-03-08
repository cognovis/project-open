<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="set_content_method_default">      
      <querytext>

        select content_method__set_default_method (
                :content_type,
                :content_method
        );
  
      </querytext>
</fullquery>

 
</queryset>
