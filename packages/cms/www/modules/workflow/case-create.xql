<?xml version="1.0"?>
<queryset>

<fullquery name="insert_deadlines">      
      <querytext>
      
	      insert into wf_case_deadlines (
	        case_id, workflow_key, transition_key, deadline
	      ) values (
	        :case_id, 'publishing_wf', :transition, $dead_sql
	      )
      </querytext>
</fullquery>

 
<fullquery name="update_deadlines">      
      <querytext>
      
	      update 
	        wf_case_deadlines 
	      set
	        deadline = $new_dead_sql
	      where
	        workflow_key = 'publishing_wf' 
	      and 
	        transition_key = :transition
	      and 
	        case_id = :case_id
      </querytext>
</fullquery>


<fullquery name="get_name_key">      
      <querytext>
  select 
    transition_name, transition_key 
  from 
    wf_transitions
  where 
    workflow_key = 'publishing_wf' 
  order by 
    sort_order      
      </querytext>
</fullquery>

 
</queryset>
