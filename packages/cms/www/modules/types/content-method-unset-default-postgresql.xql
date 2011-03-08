<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unset_content_method_default">      
      <querytext>

        select content_method__unset_default_method (
                :content_type
        );
 

      </querytext>
</fullquery>

 
</queryset>
