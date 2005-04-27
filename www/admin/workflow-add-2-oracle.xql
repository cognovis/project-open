<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_workflow">      
      <querytext>
      
    declare
        v_workflow_key varchar(40);
    begin
        v_workflow_key := workflow.create_workflow(
            workflow_key => :workflow_key,
            pretty_name => :workflow_name, 
            pretty_plural => :workflow_name, 
     	    description => :description,
  	    table_name => :workflow_cases_table
        );
    end;
    
      </querytext>
</fullquery>

 
</queryset>
