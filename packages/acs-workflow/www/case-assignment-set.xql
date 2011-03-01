<?xml version="1.0"?>
<queryset>

<fullquery name="role_name_select">      
      <querytext>
      
select role_name
from wf_roles
where role_key = :role_key
and workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="assignment_select">      
      <querytext>
      
    select party_id
      from wf_case_assignments
     where case_id = :case_id
       and role_key = :role_key
       and workflow_key = :workflow_key

      </querytext>
</fullquery>

 
</queryset>
