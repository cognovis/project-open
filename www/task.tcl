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

set user_id [ad_get_user_id]

# Fire all message transitions before:
wf_sweep_message_transition_tcl


####################
#
# Process the form
#
####################

#
# NOTE! We need to add some double-click protection here.
#


set the_action [array names action]
if { [llength $the_action] > 1 } {
    ad_return_error "Invalid input" "More than one action was requested"
    ad_script_abort
} elseif { [llength $the_action] == 1 } {
    
    set journal_id [wf_task_action -user_id $user_id -msg $msg -attributes [array get attributes] -assignments [array get assignments] $task_id $the_action]

    ad_returnredirect "task?[export_url_vars task_id return_url]"
    return
}



####################
#
# Output the page
#
####################




array set task [wf_task_info $task_id]

set task(add_assignee_url) "assignee-add?[export_url_vars task_id]"
set task(assign_yourself_url) "assign-yourself?[export_vars -url {task_id return_url}]"
set task(manage_assignments_url) "task-assignees?[export_vars -url {task_id return_url}]"
set task(cancel_url) "task?[export_vars -url {task_id return_url {action.cancel Cancel}}]"
set task(action_url) "task"

set context [list [list "case?case_id=$task(case_id)" "$task(object_name) case"] "$task(task_name)"]

set panel_color "#dddddd"

template::multirow create panels header template_url bgcolor

set this_user_is_assigned_p $task(this_user_is_assigned_p)

db_multirow panels panels {
    select tp.header, 
           tp.template_url,
           '' as bgcolor
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and :this_user_is_assigned_p = 1))
       and tp.overrides_action_p = 'f'
    order by tp.sort_order
} {
    set bgcolor $panel_color
}

# Only display the default-info-panel when we have nothing better
if { ${panels:rowcount} == 0 } {
    template::multirow append panels "Case" "task-default-info" $panel_color
}

# Display instructions, if any
if { [db_string instruction_check "
    select count(*) 
    from wf_transition_info ti, wf_tasks t
    where t.task_id = :task_id
      and t.transition_key = ti.transition_key
      and t.workflow_key = ti.workflow_key
      and instructions is not null
"] } {
    template::multirow append panels "Instructions" "task-instructions" $panel_color
}

# Now for action panels -- these are always displayed at the far right

set override_action 0
db_foreach action_panels {
    select tp.header, 
           tp.template_url
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and :this_user_is_assigned_p = 1))
       and tp.overrides_action_p = 't'
    order by tp.sort_order
} {
    set override_action 1
    template::multirow append panels $header $template_url "#ffffff"
}

if { $override_action == 0 } {
    template::multirow append panels "Action" "task-action" "#ffffff"
}

set panel_width [expr {100/(${panels:rowcount})}]

set case_id $task(case_id)


set case_state [db_string case_state "select state from wf_cases where case_id = :case_id"]

set extreme_p 0
if {[string compare $case_state "active"] == 0} {
    set extreme_p 1
    template::multirow create extreme_actions url title
    template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=suspend" "suspend case"
    template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=cancel" "cancel case"
}



# Fire all message transitions after the action:
wf_sweep_message_transition_tcl



set export_form_vars [export_vars -form {task_id return_url}]

ad_return_template
