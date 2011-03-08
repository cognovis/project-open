<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select count(*) from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="role_exists">      
      <querytext>
      
	select count(*) from wf_roles 
	where workflow_key = :workflow_key
        and role_key = :role_key
      </querytext>
</fullquery>

 
<fullquery name="workflow">      
      <querytext>
      
    select w.workflow_key, 
           t.pretty_name
    from   wf_workflows w, 
           acs_object_types t 
    where  w.workflow_key = :workflow_key 
    and    w.workflow_key = t.object_type

      </querytext>
</fullquery>

 
<fullquery name="role">      
      <querytext>
      
    select role_name
    from wf_roles
    where workflow_key = :workflow_key
    and role_key = :role_key

      </querytext>
</fullquery>

 
<fullquery name="workflow_transitions">      
      <querytext>
      
    select transition_name,
           transition_key
    from wf_transitions
    where workflow_key = :workflow_key
    and role_key is null
    order by sort_order

      </querytext>
</fullquery>

 
</queryset>
