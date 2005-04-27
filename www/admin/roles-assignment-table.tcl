#
# Display roles for a process.
#
# Input:
#   workflow_key
#   return_url (optional)
#   context (optional)
#
# Data sources:
#   roles
#   role_add_url
#
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 26, 2001
# Cvs-id: $Id$

if { ![info exists context_key] } {
    set context_key "default"
}

db_multirow roles roles {
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
} {
    set delete_url "role-delete?[export_vars -url {workflow_key role_key return_url}]"
    set edit_url "role-edit?[export_vars -url {workflow_key role_key return_url}]"
    set static_url "role-static?[export_vars -url {workflow_key role_key return_url}]"
    set manual_url "role-manual?[export_vars -url {workflow_key role_key return_url}]"
    set programmatic_url "role-programmatic?[export_vars -url {workflow_key role_key return_url}]"
    if { [empty_string_p $assignment_callback] && [empty_string_p $assigning_transition_key] } {
	set is_static_p 1
    }
}

set role_add_url "role-add?[export_vars -url {workflow_key return_url}]"

ad_return_template


