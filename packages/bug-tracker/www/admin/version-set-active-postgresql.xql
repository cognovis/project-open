<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="set_active_version">      
      <querytext>

    select bt_version__set_active(:version_id);

      </querytext>
</fullquery>

 
</queryset>
