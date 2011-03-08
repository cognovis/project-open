<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_workflow">      
      <querytext>

	select workflow__create_workflow(
            :workflow_key,
            :workflow_name, 
            :workflow_name, 
     	    :description,
  	    :workflow_cases_table,
	    'case_id'
        );

      </querytext>
</fullquery>

 
<fullquery name="constraints">      
      <querytext>

        select tgconstrname::text from pg_trigger

      </querytext>
</fullquery>

</queryset>
