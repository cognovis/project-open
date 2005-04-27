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

 
</queryset>
