<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_keyword">
  <querytext>
    select content_keyword__delete(:keyword_id)
  </querytext>
</fullquery>

</queryset>
