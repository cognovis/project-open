<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="assign_keyword">      
      <querytext>
      

       begin content_keyword.item_assign(:resolved_id, :item_id); end;

            
      </querytext>
</fullquery>

 
</queryset>
