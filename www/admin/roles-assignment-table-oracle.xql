<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="roles">      
      <querytext>
      
    select r.sort_order, 
           r.role_key,
           r.role_name,
           '' as delete_url,
           '' as edit_url,
           '' as static_url,
           '' as manual_url,
           '' as programmatic_url,
           0 as is_static_p,
           cri.assignment_callback,
           cri.assignment_custom_arg,
           map.transition_key as assigning_transition_key,
           t.transition_name as assigning_transition_name
      from wf_roles r, wf_context_role_info cri, wf_transition_role_assign_map map, wf_transitions t
     where r.workflow_key = :workflow_key
       and cri.context_key (+) = :context_key
       and cri.workflow_key (+) = r.workflow_key
       and cri.role_key (+) = r.role_key
       and map.workflow_key (+) = r.workflow_key
       and map.assign_role_key (+) = r.role_key
       and t.workflow_key (+) = map.workflow_key
       and t.transition_key (+) = map.transition_key
     order by r.sort_order

      </querytext>
</fullquery>

 
</queryset>
