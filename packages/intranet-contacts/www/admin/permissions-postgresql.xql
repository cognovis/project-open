<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>



<fullquery name="get_object_name">
  <querytext>
        select acs_object__name(:object_id) as object_name
  </querytext>
</fullquery>

</queryset>
