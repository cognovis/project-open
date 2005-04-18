<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_type">      
      <querytext>

        select content_folder__register_content_type(
               :folder_id,
               :type,
               'f'
           );
         
      </querytext>
</fullquery>

 
</queryset>
