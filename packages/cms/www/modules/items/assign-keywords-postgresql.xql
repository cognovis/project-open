<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="item_assign">      
      <querytext>


        select content_keyword__item_assign(
          :root_id, :item_id, null, :user_id, :ip); 

      </querytext>
</fullquery>

 
</queryset>
