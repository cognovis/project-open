<?xml version="1.0"?>
<queryset>

<fullquery name="static_assignment_add">      
      <querytext>
      
    insert into wf_context_assignments
        (workflow_key, context_key, role_key, party_id)
    values
        (:workflow_key, :context_key, :role_key, :party_id)

      </querytext>
</fullquery>

 
</queryset>
