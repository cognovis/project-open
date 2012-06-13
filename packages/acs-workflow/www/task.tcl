ad_page_contract {
    Displays information about a specific task.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 13 July 2000
    @cvs-id $Id$
} {
    task_id:integer,notnull
    {action:array {}}
    {attributes:array {}}
    {assignments:array,multiple {}}
    {msg:html {}}
    {vertical:integer 0}
    {return_url ""}
    {force_return_url 0}
} -properties {
    case_id
    context
    task:onerow
    task_html
    user_id
    return_url
    export_form_vars
    extreme_p 
}

# ---------------------------------------------------------
# Defaults & Security

# We don't force the user to authentify, is that right?
set user_id [ad_get_user_id]
set current_url [im_url_with_query]

# ToDo: NOTE! We need to add some double-click protection here.

set the_action [array names action]
if { [llength $the_action] > 1 } {
    ad_return_error "Invalid input" "More than one action was requested"
    ad_script_abort
} elseif { [llength $the_action] == 1 } {
    
    set journal_id [wf_task_action -user_id $user_id -msg $msg -attributes [array get attributes] -assignments [array get assignments] $task_id $the_action]

    # After a "finish" action we can go back to return_url directly.
    if {"finish" == $the_action} { ad_returnredirect $return_url }

    # Otherwise go back to the tasks's page
    ad_returnredirect "task?[export_url_vars task_id return_url]"

    ad_script_abort
}


# ---------------------------------------------------------
# Fire all message transitions before:

wf_sweep_message_transition_tcl



# ---------------------------------------------------------
# Get everything about the task


if {[catch {
    array set task [wf_task_info $task_id]
} err_msg]} {
    ad_return_complaint 1 "<li>
	<b>[lang::message::lookup "" acs-workflow.Task_not_found "Task not found:"]</b><p>
	[lang::message::lookup "" acs-workflow.Task_not_found_message "
		This error can occur if a system administrator has deleted a workflow.<br>
		This situation should not occur during normal operations.<p>
		Please contact your System Administrator
	"]
    "
    return
}

set task(add_assignee_url) "assignee-add?[export_url_vars task_id]"
set task(assign_yourself_url) "assign-yourself?[export_vars -url {task_id {return_url $current_url}}]"
set task(manage_assignments_url) "task-assignees?[export_vars -url {task_id {return_url $current_url}}]"
set task(cancel_url) "task?[export_vars -url {task_id return_url {action.cancel Cancel}}]"
set task(action_url) "task"
set task(return_url) $return_url

set task_name "undefined"
if {[info exists task(task_name)]} { set task_name $task(task_name)}

set context [list [list "case?case_id=$task(case_id)" "$task(object_name) case"] $task_name]
set panel_color "#dddddd"

set show_action_panel_p 1

# ---------------------------------------------------------
# Get "information panel" information - displayed on the left usually

template::multirow create panels header template_url bgcolor
set this_user_is_assigned_p $task(this_user_is_assigned_p)

db_multirow panels panels {} {
    set bgcolor $panel_color
    if {"t" == $overrides_both_panels_p} { set show_action_panel_p 0 }
}

# Only display the default-info-panel when we have nothing better
if { ${panels:rowcount} == 0 } {
    template::multirow append panels "Case" "task-default-info" $panel_color
}


# ---------------------------------------------------------
# Display instructions, if any

if { [db_string instruction_check ""] } {
    template::multirow append panels "Instructions" "task-instructions" $panel_color
}


# ---------------------------------------------------------
# Now for action panels -- these are always displayed at the far right

if {$show_action_panel_p} {

    set override_action 0
    db_foreach action_panels {} {
	set override_action 1
	template::multirow append panels $header $template_url "#ffffff"
    }

    if { $override_action == 0 } {
	template::multirow append panels "Action" "task-action" "#ffffff"
    }
}

set panel_width [expr {100/(${panels:rowcount})}]
set case_id $task(case_id)
set case_state [db_string case_state "select state from wf_cases where case_id = :case_id"]

# ---------------------------------------------------------
# "Extreme Actions" - cancel and/or suspend the case

set extreme_p 0

set wf_suspend_case_p [permission::permission_p -party_id $user_id -object_id [ad_conn subsite_id] -privilege "wf_suspend_case"]
set wf_cancel_case_p [permission::permission_p -party_id $user_id -object_id [ad_conn subsite_id] -privilege "wf_cancel_case"]

if { [string compare $case_state "active"] == 0 && ($wf_suspend_case_p || $wf_cancel_case_p) } {
    set extreme_p 1
    template::multirow create extreme_actions url title
    if { $wf_suspend_case_p } { template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=suspend" [lang::message::lookup "" intranet-workflow.Suspend_Case "Suspend Case"]}
    if { $wf_cancel_case_p } { template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=cancel" [lang::message::lookup "" intranet-workflow.Cancel_Case "Cancel Case"]}
}
 
# ---------------------------------------------------------
# Fire all message transitions after the action:

wf_sweep_message_transition_tcl

set export_form_vars [export_vars -form {task_id return_url}]

ad_return_template
