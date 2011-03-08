<?xml version="1.0"?>
<queryset>

<fullquery name="panel_delete">      
      <querytext>
      
    delete from wf_context_task_panels
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    context_key = :context_key
    and    sort_order = :sort_order

      </querytext>
</fullquery>

 
</queryset>
