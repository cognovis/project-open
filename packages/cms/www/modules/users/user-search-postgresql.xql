<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_who">      
      <querytext>
      select acs_object__name(:group_id) 
      </querytext>
</fullquery>

 
</queryset>
