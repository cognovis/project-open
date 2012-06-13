ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    from_transition_key:notnull
} -validate {
    task_exists -requires { from_transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]

	wf_wizard_massage_tasks $tasks_client_property task_list task
	
	if { ![info exists task($from_transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
}

set index [lsearch -exact $task_list $from_transition_key]

array set the_task [lindex $tasks_client_property $index]
set the_task(loop_to_transition_key) ""
set the_task(loop_question) ""
set the_task(loop_answer) ""

set tasks_client_property [lreplace $tasks_client_property $index $index [array get the_task]]

ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect loops
