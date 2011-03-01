<?xml version="1.0"?>
<queryset>

<fullquery name="attribute_move_up">      
      <querytext>

	update wf_transition_attribute_map
	set    sort_order = case when sort_order = :sort_order then :prior_sort_order when sort_order = :prior_sort_order then :sort_order end
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    sort_order in (:sort_order, :prior_sort_order)
    
      </querytext>
</fullquery>

 
</queryset>
