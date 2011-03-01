<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_workflow">      
      <querytext>
        select workflow__create_workflow(
            '[db_quote $workflow_key]',
            '[db_quote $workflow_name]', 
            '[db_quote $workflow_name]', 
     	    '[db_quote $workflow_description]',
  	    '[db_quote $workflow_cases_table]',
	    'case_id'
        );
    
      </querytext>
</fullquery>

 
<fullquery name="define_attribute">      
      <querytext>

	select workflow__create_attribute(
	            '[db_quote $workflow_key]',
	            '[db_quote $task($transition_key,loop_attribute_name)]',
	            'boolean',
	            '[db_quote "$task($transition_key,loop_question)"]',
		    null,
		    null,
		    null,
      	            '[ad_decode $task($transition_key,loop_answer) "t" "f" "t"]',
		    1,
		    1,
		    null,
		    'generic'
	        );
      </querytext>
</fullquery>


<fullquery name="constraints">      
      <querytext>

        select tgconstrname::text from pg_trigger

      </querytext>
</fullquery>

 
</queryset>
