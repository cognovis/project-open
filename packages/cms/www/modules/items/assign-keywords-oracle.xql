<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="item_assign">      
      <querytext>
      
        begin 
         :1 := content_keyword.item_assign(
          :root_id, :item_id, null, :user_id, :ip); 
        end;
      </querytext>
</fullquery>

 
</queryset>
