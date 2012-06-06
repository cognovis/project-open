#
# Display transitions for a process.
#
# Input:
#   workflow_key
#   return_url (optional)
#   context (optional)
#   modifiable_p (optional)
#
# Data sources:
#   transitions
#   transition_add_url
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

array set trigger_type_pretty_array {
    user ""
    automatic Auto
    message Message
    time Time
}

db_multirow transitions transtitions {
    select t.sort_order, 
           t.transition_key,
           t.transition_name,
           t.trigger_type,
           '' as trigger_type_pretty,
           t.role_key,
           r.role_name,
           '' as delete_url,
           '' as edit_url,
           '' as role_edit_url
      from wf_transitions t, wf_roles r
     where t.workflow_key = :workflow_key
       and r.workflow_key (+) = t.workflow_key
       and r.role_key (+) = t.role_key
     order by t.sort_order
} {
    # For some reason we seem to need to ns_urlencode the whole thing again when we use it in a javascript thing
    if { $modifiable_p } { 
	set delete_url "javascript:if(confirm('Are you sure you want to delete this transition?'))location.href='task-delete?[export_vars -url {workflow_key transition_key}]'"
    }
    set edit_url "task-edit?[export_vars -url {workflow_key transition_key return_url}]"
    set role_edit_url "role-edit?[export_vars -url {workflow_key role_key return_url}]"
    set trigger_type_pretty $trigger_type_pretty_array($trigger_type)
}

set transition_add_url "task-add?[export_vars -url {workflow_key return_url}]"

ad_return_template


