<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_keyword">      
      <querytext>

     select content_keyword__delete(:id);

      </querytext>
</fullquery>

 
<fullquery name="get_empty_status">      
      <querytext>
      
  select content_keyword__is_leaf(:id) 

      </querytext>
</fullquery>

 
</queryset>
