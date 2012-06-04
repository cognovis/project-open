ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    from_transition_key:notnull
} -validate {
    task_exists -requires { from_transition_key:notnull } {
	wf_wizard_massage_tasks [ad_get_client_property wf tasks] task_list task tasks
	if { ![info exists task($from_transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
} -properties {
    workflow_name
    context
    task_name
    to_transitions
}

set workflow_name [ad_quotehtml [ad_get_client_property wf workflow_name]]

set task_name [ad_quotehtml $task($from_transition_key,task_name)]

set context [list [list "" "Simple Process Wizard"] [list "loops" "Loops"] "Add loop from $task_name"]

set export_vars [export_form_vars from_transition_key]

template::multirow create to_transitions transition_key task_name

foreach transition_key $task_list {
    template::multirow append to_transitions $transition_key $task($transition_key,task_name)
    if { [string equal $transition_key $from_transition_key] } {
	break
    }
}


ad_return_template
