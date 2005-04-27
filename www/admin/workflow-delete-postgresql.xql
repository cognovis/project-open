<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_cases">      
      <querytext>

	select workflow__delete_cases(:workflow_key);

      </querytext>
</fullquery>

 
<fullquery name="delete_workflow">      
      <querytext>

	select workflow__drop_workflow(:workflow_key);

      </querytext>
</fullquery>

 
</queryset>
