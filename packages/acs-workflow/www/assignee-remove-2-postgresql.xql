<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="remove_assignee_task">      
      <querytext>

        begin
            PERFORM workflow_case__remove_task_assignment (
                :task_id,
                :party_id
            );

            PERFORM workflow_case__remove_manual_assignment (
                :case_id,
                :transition_key,
                :party_id
            );

           return null;
        end;
    
      </querytext>
</fullquery>

 
</queryset>
