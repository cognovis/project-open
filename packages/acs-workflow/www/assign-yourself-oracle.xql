<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="add_self_case">      
      <querytext>
      
    begin
        workflow_case.add_manual_assignment (
            case_id => :case_id,
            transition_key => :transition_key,
            party_id => :user_id
        );
    end;

      </querytext>
</fullquery>

 
<fullquery name="add_self_task">      
      <querytext>
      
    begin
        workflow_case.add_task_assignment (
            task_id => :task_id,
            party_id => :user_id
        );
    end;

      </querytext>
</fullquery>

 
</queryset>
