<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_keyword">
  <querytext>
      begin
          content_keyword.del(:keyword_id);
      end;
  </querytext>
</fullquery>
 
</queryset>
