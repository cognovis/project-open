<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_folder">      
      <querytext>

        select content_folder__delete(:id)

      </querytext>
</fullquery>

 
<fullquery name="check_empty">      
      <querytext>
      
  select content_folder__is_empty(:id) 

      </querytext>
</fullquery>

 
</queryset>
