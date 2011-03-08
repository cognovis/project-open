<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select 1 from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="workflow_name">      
      <querytext>
      
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="transitions">      
      <querytext>
      
    select transition_key, transition_name 
    from   wf_transitions
    where  workflow_key = :workflow_key
    order by transition_name

      </querytext>
</fullquery>

 
<fullquery name="places">      
      <querytext>
      
    select place_key, place_name
    from   wf_places
    where  workflow_key = :workflow_key
    order by place_name

      </querytext>
</fullquery>

 
</queryset>
