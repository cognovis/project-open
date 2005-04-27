<?xml version="1.0"?>
<queryset>

<fullquery name="prior_sort_key">      
      <querytext>
       
	select max(sort_key) 
	from   wf_context_task_panels
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
	and    sort_key < :sort_key
    
      </querytext>
</fullquery>

 
<fullquery name="panel_move_up">      
      <querytext>

	update wf_context_task_panels
	set    sort_key = case when sort_key = :sort_key then :prior_sort_key when sort_key = :prior_sort_key then :sort_key end
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
	and    sort_key in (:sort_key, :prior_sort_key)
    
      </querytext>
</fullquery>

 
</queryset>
