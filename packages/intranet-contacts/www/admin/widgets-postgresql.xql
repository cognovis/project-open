<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>



<fullquery name="get_widgets">
  <querytext>
        select * from contact_widgets order by storage_column, description
  </querytext>
</fullquery>


</queryset>
