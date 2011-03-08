<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="set_active_version">      
      <querytext>
      begin
        bt_version.set_active(:version_id);
      end;

      </querytext>
</fullquery>

 
</queryset>
