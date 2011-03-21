<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_cases">      
      <querytext>
      
    begin 
        workflow.delete_cases(workflow_key => :workflow_key);
    end;

      </querytext>
</fullquery>

 
</queryset>
