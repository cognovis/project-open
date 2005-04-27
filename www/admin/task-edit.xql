<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select pretty_name as workflow_name
      from acs_object_types
     where object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="transition_info">      
      <querytext>
      
    select transition_name,
           trigger_type,
           role_key as selected_role_key
    from   wf_transitions
    where  transition_key = :transition_key
    and    workflow_key = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="roles">      
      <querytext>
      
    select r.role_key, 
           r.role_name,
           case when role_key = :selected_role_key then 'SELECTED' else '' end as selected_string 
      from wf_roles r
     where r.workflow_key = :workflow_key
     order by r.sort_order

      </querytext>
</fullquery>

 
<fullquery name="transition_context_info">      
      <querytext>
      
    select estimated_minutes, instructions 
      from wf_context_transition_info 
     where workflow_key = :workflow_key 
       and transition_key = :transition_key 
       and context_key = :context_key

      </querytext>
</fullquery>

 
</queryset>
