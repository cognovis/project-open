<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="add_self_case">      
      <querytext>

    select workflow_case__add_manual_assignment (
            :case_id,
            :transition_key,
            :user_id
        );

      </querytext>
</fullquery>

 
<fullquery name="add_self_task">      
      <querytext>

      select workflow_case__add_task_assignment (
            :task_id,
            :user_id,
			'f'
        );

      </querytext>
</fullquery>

 
</queryset>
