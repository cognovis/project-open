<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_item_id">      
      <querytext>
      
  select content_symlink__resolve(:item_id) 

      </querytext>
</fullquery>

 
</queryset>
