<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="transition_attribute_add">      
      <querytext>
      
    insert into wf_transition_attribute_map (workflow_key, transition_key, sort_order, attribute_id)
    select :workflow_key, :transition_key, nvl(max(sort_order)+1,1), :attribute_id
    from wf_transition_attribute_map
    where workflow_key = :workflow_key
    and   transition_key = :transition_key

      </querytext>
</fullquery>

 
</queryset>
