<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unset_live_revision">      
      <querytext>

        select content_item__unset_live_revision( :item_id );
        
      </querytext>
</fullquery>

 
</queryset>
