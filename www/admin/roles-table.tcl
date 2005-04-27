#
# Display roles for a process.
#
# Input:
#   workflow_key
#   return_url (optional)
#   context (optional)
#   modifiable_p (optional)
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

if { ![info exists modifiable_p] } {
    set modifiable_p 1
}

set row_count 0
set role_count 0
set last_role_key {}
db_multirow roles roles {
    select r.sort_order, 
           r.role_key,
           r.role_name,
           '' as delete_url,
           '' as edit_url,
           '' as move_up_url,
           '' as move_down_url,
           0 as role_no,
           t.transition_key,
           t.transition_name,
           '' as transition_edit_url
      from wf_roles r, wf_transitions t
     where r.workflow_key = :workflow_key
       and t.workflow_key (+) = r.workflow_key
       and t.role_key (+) = r.role_key
     order by r.sort_order, t.sort_order
} {
    incr row_count
    if { ![string equal $role_key $last_role_key] } {
	incr role_count
	set last_role_key $role_key
    }
    # For some reason we seem to need to ns_urlencode the whole thing again, when using it in javascript
    if { $modifiable_p } {
	set delete_url [ad_quotehtml "javascript:if(confirm('Are you sure you want to delete this role?'))location.href='role-delete?[export_vars -url {workflow_key role_key return_url}]'"]
    }

#    set delete_url "role-delete?[export_vars -url {workflow_key role_key return_url}]"
    set edit_url "role-edit?[export_vars -url {workflow_key role_key return_url}]"
    if { $row_count > 1 } {
	set move_up_url "role-move-up?[export_vars -url {workflow_key role_key return_url}]"
    }
    set move_down_url "role-move-down?[export_vars -url {workflow_key role_key return_url}]"
    set role_no $role_count
    if { ![empty_string_p $transition_key] } {
	set transition_edit_url "task-edit?[export_vars -url {workflow_key transition_key return_url context_key}]"
    }
}

for { set i $row_count } { $i > 0 && [string equal [template::multirow get roles $i role_key] $last_role_key] } { incr i -1 } {
    template::multirow set roles $i move_down_url ""
}

set role_add_url "role-add?[export_vars -url {workflow_key return_url}]"

ad_return_template


