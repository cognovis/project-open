<?xml version="1.0"?>
<queryset>

<fullquery name="static_assignment_delete">      
      <querytext>
      
    delete
    from   wf_context_assignments
    where  workflow_key = :workflow_key
    and    context_key = :context_key
    and    role_key = :role_key
    and    party_id = :party_id

      </querytext>
</fullquery>

 
</queryset>
