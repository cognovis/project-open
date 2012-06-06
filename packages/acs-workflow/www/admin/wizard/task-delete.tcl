ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    transition_key:notnull
} -validate {
    task_exists -requires { transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]

	wf_wizard_massage_tasks $tasks_client_property task_list task
	
	if { ![info exists task($transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
}


set index [lsearch -exact $task_list $transition_key]
set tasks_client_property [lreplace $tasks_client_property $index $index]

# remove loops/assignments that refer to this task
set counter 0
foreach transition_info $tasks_client_property {
    array set test_task $transition_info
    set changed_p 0
    if { [string equal $test_task(loop_to_transition_key) $transition_key] } {
	set test_task(loop_to_transition_key) {}
	set changed_p 1
    }
    if { [string equal $test_task(assigning_transition_key) $transition_key] } {
	set test_task(assigning_transition_key) {}
	set changed_p 1
    }
    if { $changed_p } {
	# this doesn't interfere with the loop, because the tasks_client_property has alredy been expanded
	set tasks_client_property [lreplace $tasks_client_property $counter $counter [array get test_task]]
    }
    incr counter
}

ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect tasks
