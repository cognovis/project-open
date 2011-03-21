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
      
    select role_name
      from wf_roles
     where workflow_key = :workflow_key
       and role_key = :role_key

      </querytext>
</fullquery>

 
<fullquery name="transitions">      
      <querytext>
      
    select t.transition_key,
           t.transition_name
      from wf_transitions t
     where t.workflow_key = :workflow_key
       and not exists (select 1 
                         from wf_transition_role_assign_map m 
                        where m.workflow_key = t.workflow_key  
                          and m.transition_key = t.transition_key 
                          and m.assign_role_key = :role_key)
     order by t.sort_order

      </querytext>
</fullquery>

 
</queryset>
