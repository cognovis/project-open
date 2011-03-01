<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="add_assignee_task">      
      <querytext>

        select workflow_case__add_task_assignment (
                    :task_id,
                    :party_id,
					'f'
                );
        
      </querytext>
</fullquery>

 
<fullquery name="add_assignee_case">      
      <querytext>

            select workflow_case__add_manual_assignment (
                    :case_id,
                    :transition_key,
                    :party_id
                );
        
      </querytext>
</fullquery>

 
</queryset>
