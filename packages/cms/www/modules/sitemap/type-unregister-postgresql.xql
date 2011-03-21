<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unregister">      
      <querytext>


        select content_folder__unregister_content_type(
               :folder_id,
               :type_key,
               'f' 
           );
        
      </querytext>
</fullquery>

 
</queryset>
