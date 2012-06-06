#
# Display panels for a process
#
# Input:
#   workflow_key
#   return_url (optional)
#   context (optional)
#
# Data sources:
#   transitions
#   transition_add_url
#
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 27, 2001
# Cvs-id: $Id$

if { ![info exists context_key] } {
    set context_key "default"
}

set row_count 0 
set panel_count 0
set last_transition_key {}
db_multirow panels panels {
    select t.transition_key,
           t.transition_name,
           '' as transition_edit_url,
           '' as panel_add_url,
           pan.sort_order,
           0 as panel_no,
           pan.header,
           pan.template_url,
           pan.template_url as template_url_pretty,
           pan.overrides_action_p,
           pan.only_display_when_started_p,
           0 as rowspan,
           '' as panel_edit_url,
           '' as panel_delete_url
      from wf_transitions t, wf_context_task_panels pan
     where t.workflow_key = :workflow_key
       and pan.workflow_key (+) = t.workflow_key
       and pan.context_key (+) = :context_key
       and pan.transition_key (+) = t.transition_key
     order by t.sort_order, pan.sort_order
} {
    incr row_count
    if { ![string equal $transition_key $last_transition_key] } {
	set panel_count 0
	set last_transition_key $transition_key
    }
    incr panel_count
    # For some reason we seem to need to ns_urlencode the whole thing again when we use it in a javascript thing
#    set delete_url 

    set panel_add_url "task-panel-add?[export_vars -url {workflow_key transition_key context_key return_url}]"
    set panel_edit_url "task-panel-edit?[export_vars -url {sort_order workflow_key transition_key context_key return_url}]"
    set panel_delete_url "task-panel-delete?[export_vars -url {sort_order workflow_key transition_key context_key return_url}]"

    set transition_edit_url "task-edit?[export_vars -url {workflow_key transition_key return_url}]"
    set panel_no $panel_count
    if { [string length $template_url] > 30 } { 
	set len [string length $template_url]
	set slash [string first "/" $template_url [expr { $len - 30 }]]
	if { $slash == -1 } { 
	    set slash [string last "/" $template_url [expr { $len - 30 }]]
	}
	set template_url_pretty "...[string range $template_url $slash end]"
    }
}

for { set i $row_count } { $i > 0 } { incr i -1 } {
    set panel_no [template::multirow get panels $i panel_no]
    incr i [expr -$panel_no + 1]
    template::multirow set panels $i rowspan $panel_no
}

#set transition_add_url "task-add?[export_vars -url {workflow_key return_url}]"

ad_return_template


