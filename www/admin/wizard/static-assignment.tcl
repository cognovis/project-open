ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    transition_key:notnull
} -validate {
    task_exists -requires { transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]
	wf_wizard_massage_tasks $tasks_client_property tasks task
	if { ![info exists task($transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
}

set index [lsearch -exact $tasks $transition_key]
array set edit_task [lindex $tasks_client_property $index]

set edit_task(assigning_transition_key) {}

set tasks_client_property [lreplace $tasks_client_property $index $index [array get edit_task]]

ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect assignments
