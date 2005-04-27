<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="role_info">      
      <querytext>
      
    select role_key,
           role_name
      from wf_roles
     where workflow_key = :workflow_key
       and role_key = :role_key

      </querytext>
</fullquery>

 
</queryset>
