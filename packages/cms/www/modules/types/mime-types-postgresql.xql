<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_mime_type">      
      <querytext>

        select content_type__register_mime_type (
            :content_type,
            :mime_type
        );
      
      </querytext>
</fullquery>

 
</queryset>
