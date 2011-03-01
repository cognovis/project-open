<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="remove_assignee_task">      
      <querytext>
      
        begin
            workflow_case.remove_task_assignment (
                task_id => :task_id,
                party_id => :party_id
            );

            workflow_case.remove_manual_assignment (
                case_id => :case_id,
                transition_key => :transition_key,
                party_id => :party_id
            );
        end;
    
      </querytext>
</fullquery>

 
</queryset>
