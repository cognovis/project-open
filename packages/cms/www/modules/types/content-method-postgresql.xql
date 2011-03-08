<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="add_method">      
      <querytext>

        select content_method__add_method (
          :content_type,
          :content_method,
          'f'
      );
    
      </querytext>
</fullquery>

 
</queryset>
