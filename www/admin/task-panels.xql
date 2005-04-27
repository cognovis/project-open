<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select 1 from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="workflow_and_transition_name">      
      <querytext>
      
    select ot.pretty_name as workflow_name,
           t.transition_name
    from   acs_object_types ot,
           wf_transitions t
    where  ot.object_type = :workflow_key
    and    t.workflow_key = ot.object_type
    and    t.transition_key = :transition_key

      </querytext>
</fullquery>

 
<fullquery name="context_slider">      
      <querytext>
      
    select context_key as context_key_from_db,
           context_name as title,
           '' as url,
           0 as selected_p
    from   wf_contexts
    order by context_name

      </querytext>
</fullquery>

 
<fullquery name="panels">      
      <querytext>
      
    select tp.sort_order,
           tp.header, 
           tp.template_url,
           '' as edit_url,
           '' as delete_url,
           '' as move_up_url
    from   wf_context_task_panels tp
    where  tp.context_key = :context_key
    and    tp.workflow_key = :workflow_key
    and    tp.transition_key = :transition_key
    order by sort_order

      </querytext>
</fullquery>

 
</queryset>
