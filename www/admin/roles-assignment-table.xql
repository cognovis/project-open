<?xml version="1.0"?>
<queryset>

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
      from ((wf_roles r LEFT OUTER JOIN wf_context_role_info cri
	     ON (r.workflow_key = cri.workflow_key and cri.context_key = :context_key and cri.role_key = r.role_key)) LEFT OUTER JOIN  wf_transition_role_assign_map map
	       ON (r.workflow_key = map.workflow_key and r.role_key = map.assign_role_key)) LEFT OUTER JOIN  wf_transitions t ON (map.workflow_key = t.workflow_key and map.transition_key = t.transition_key)
     where r.workflow_key = :workflow_key
     order by r.sort_order

      </querytext>
</fullquery>

 
</queryset>
