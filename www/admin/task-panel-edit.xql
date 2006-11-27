<?xml version="1.0"?>
<queryset>

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

 
<fullquery name="panel">      
      <querytext>
      
    select p.header,
           p.template_url,
           p.overrides_action_p,
           p.overrides_both_panels_p,
           p.only_display_when_started_p
    from   wf_context_task_panels p
    where  p.workflow_key = :workflow_key
    and    p.transition_key = :transition_key
    and    p.context_key = :context_key
    and    p.sort_order = :sort_order

      </querytext>
</fullquery>

 
</queryset>
