<?xml version="1.0"?>
<queryset>

<fullquery name="panel_update">      
      <querytext>
      
	update wf_context_task_panels
	set    header = :header,
	       template_url = :template_url,
               overrides_action_p = :overrides_action_p,
	       only_display_when_started_p = :only_display_when_started_p
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
	and    sort_order = :sort_order
    
      </querytext>
</fullquery>

 
</queryset>
