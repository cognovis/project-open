<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unassign_keyword">      
      <querytext>

  select content_keyword__item_unassign(:resolved_id, :keyword_id)

      </querytext>
</fullquery>

 
</queryset>
