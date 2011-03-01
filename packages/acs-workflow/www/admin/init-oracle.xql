<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="object">      
      <querytext>
      
    select object_id, acs_object.name(object_id) as name from acs_objects order by name

      </querytext>
</fullquery>

 
</queryset>
