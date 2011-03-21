<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_id">      
      <querytext>
	select package_id from apm_packages where package_key='acs-workflow' limit 1
      </querytext>
</fullquery>

 
</queryset>
