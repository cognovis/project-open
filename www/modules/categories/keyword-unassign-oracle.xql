<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unassign_keyword">      
      <querytext>
      
  begin content_keyword.item_unassign(:resolved_id, :keyword_id); end;

      </querytext>
</fullquery>

 
</queryset>
