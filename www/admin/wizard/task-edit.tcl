ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    transition_key:notnull
} -validate {
    task_exists -requires { transition_key:notnull } {
	wf_wizard_massage_tasks [ad_get_client_property wf tasks] task_list task tasks
	if { ![info exists task($transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
} -properties {
    workflow_name
    context
    task_name
    task_time
}

set workflow_name [ad_get_client_property wf workflow_name]

set task_name $task($transition_key,task_name)

set task_time $task($transition_key,task_time)

set context [list [list "" "Simple Process Wizard"] [list "tasks" "Tasks"] "Edit task $task($transition_key,task_name)"]

set export_vars [export_form_vars transition_key]

ad_return_template