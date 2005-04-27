<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="roles">      
      <querytext>
      
    select r.role_key, 
           r.role_name 
      from wf_roles r
     where r.workflow_key = :workflow_key
     order by r.sort_order

      </querytext>
</fullquery>

 
</queryset>
