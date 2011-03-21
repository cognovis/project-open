<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unset_live_revision">      
      <querytext>
      begin 
           content_item.unset_live_revision( :item_id );
         end;
      </querytext>
</fullquery>

 
</queryset>
