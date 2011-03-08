<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="tasks">      
      <querytext>

    select tr.transition_key, 
           tr.transition_name,
           p.party_id,
           acs_object.name(p.party_id) as party_name,
           p.email as party_email,
           '' as user_select_widget
    from   wf_transition_info tr,
           wf_context_assignments ca,
           parties p
    where  tr.workflow_key = :workflow_key
    and    tr.context_key = :context_key
    and    tr.trigger_type = 'user'
    and    tr.assignment_callback is null
    and    ca.context_key (+) = tr.context_key
    and    ca.transition_key (+) = tr.transition_key
    and    p.party_id (+) = ca.party_id
    and    not exists 
               (select 1 
                from   wf_transition_assignment_map 
                where  workflow_key = tr.workflow_key
                and    assign_transition_key = tr.transition_key)
    order by tr.sort_order, tr.transition_key

      </querytext>
</fullquery>

<fullquery name="parties">      
      <querytext>
      
            select p.party_id as sel_party_id,
                   acs_object.name(p.party_id) as sel_name,
                   p.email as sel_email
            from   parties p
            where  p.party_id not in 
                  (select ca.party_id 
                   from   wf_context_assignments ca
                   where  ca.workflow_key = :workflow_key 
                   and    ca.context_key = :context_key 
                   and    ca.transition_key = :transition_key)
	
      </querytext>
</fullquery>
 
</queryset>
