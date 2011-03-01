<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_workflow">      
      <querytext>
      
    declare
        v_workflow_key varchar(40);
    begin
        v_workflow_key := workflow.create_workflow(
            workflow_key => '[db_quote $workflow_key]',
            pretty_name => '[db_quote $workflow_name]', 
            pretty_plural => '[db_quote $workflow_name]', 
     	    description => '[db_quote $workflow_description]',
  	    table_name => '[db_quote $workflow_cases_table]'
        );
    end;
    
      </querytext>
</fullquery>

 
<fullquery name="define_attribute">      
      <querytext>
      
	    declare
	        v_attribute_id acs_attributes.attribute_id%TYPE;
	    begin
	        v_attribute_id := workflow.create_attribute(
	            workflow_key => '[db_quote $workflow_key]',
	            attribute_name => '[db_quote $task($transition_key,loop_attribute_name)]',
	            datatype => 'boolean',
	            pretty_name => '[db_quote "$task($transition_key,loop_question)"]',
      	            default_value => '[ad_decode $task($transition_key,loop_answer) "t" "f" "t"]'
	        );
	    
	    end;
      </querytext>
</fullquery>

 
</queryset>
