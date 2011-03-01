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

 
<fullquery name="assigned_by_this">      
      <querytext>
      
    select r.role_name,
           r.role_key,
           '' as delete_url
    from   wf_transition_role_assign_map m, 
           wf_roles r
    where  m.workflow_key = :workflow_key
    and    m.transition_key = :transition_key
    and    r.workflow_key = m.workflow_key
    and    r.role_key = m.assign_role_key

      </querytext>
</fullquery>

 
<fullquery name="to_be_assigned_by_this">      
      <querytext>
      
    select r.role_name,
           r.role_key
    from   wf_roles r
    where  r.workflow_key = :workflow_key
    and    r.role_key != (select role_key from wf_transitions t where workflow_key = :workflow_key and transition_key = :transition_key)
    and    not exists (select 1 from wf_transition_role_assign_map m
                       where  m.workflow_key = :workflow_key
                       and    m.transition_key = :transition_key
                       and    m.assign_role_key = r.role_key)

      </querytext>
</fullquery>

 
</queryset>
