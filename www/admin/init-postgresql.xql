<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="object">      
      <querytext>
      
    select object_id, acs_object__name(object_id) as name from acs_objects order by name

      </querytext>
</fullquery>

 
</queryset>
