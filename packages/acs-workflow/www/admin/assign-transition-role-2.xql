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

 
<fullquery name="assign_transition_role">      
      <querytext>
      
    update wf_transitions set role_key = :role_key
    where workflow_key = :workflow_key
    and transition_key = :transition_key

      </querytext>
</fullquery>

 
</queryset>
