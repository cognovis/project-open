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

 
<fullquery name="attributes">      
      <querytext>
      
    select ta.sort_order,
           a.attribute_id,
           a.attribute_name,
           a.pretty_name,
           a.datatype,
           '' as delete_url,
           '' as move_up_url
    from   wf_transition_attribute_map ta,
           acs_attributes a
    where  ta.workflow_key = :workflow_key
    and    ta.transition_key = :transition_key
    and    a.attribute_id = ta.attribute_id
    order by sort_order

      </querytext>
</fullquery>

 
<fullquery name="attributes_not_set">      
      <querytext>
      
    select a.attribute_id,
           a.sort_order,
           a.attribute_name,
           a.pretty_name,
           a.datatype
    from   acs_attributes a
    where  a.object_type = :workflow_key
    and not exists (select 1 from wf_transition_attribute_map m
                    where  m.workflow_key = :workflow_key
                    and    m.transition_key = :transition_key
                    and    m.attribute_id = a.attribute_id)
    order by sort_order

      </querytext>
</fullquery>

 
</queryset>
