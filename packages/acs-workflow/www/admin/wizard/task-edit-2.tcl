ad_page_contract {
    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    transition_key:notnull
    task_name:trim,nohtml,notnull
    task_time:integer
} -validate {
    task_exists -requires { transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]
	wf_wizard_massage_tasks $tasks_client_property tasks task
	if { ![info exists task($transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
    task_name_unique -requires { task_exists } {
	foreach test_transition_key $tasks {
	    if { ![string equal $test_transition_key $transition_key] && \
		    [string equal $task($test_transition_key,task_name) $task_name] } {
		ad_complain "You already have a task with this name."
	    }
	}
    }
}

set new_transition_key [wf_name_to_key $task_name]

set index [lsearch -exact $tasks $transition_key]
array set edit_task [lindex $tasks_client_property $index]

set edit_task(task_name) $task_name
set edit_task(transition_key) $new_transition_key
set edit_task(task_time) $task_time

set tasks_client_property [lreplace $tasks_client_property $index $index [array get edit_task]]


# update loops/assignments that refer to this task
set counter 0
foreach transition_info $tasks_client_property {
    array set test_task $transition_info
    set changed_p 0
    if { [string equal $test_task(loop_to_transition_key) $transition_key] } {
	set test_task(loop_to_transition_key) $new_transition_key
	set changed_p 1
    }
    if { [string equal $test_task(assigning_transition_key) $transition_key] } {
	set test_task(assigning_transition_key) $new_transition_key
	set changed_p 1
    }
    if { $changed_p } {
	# this doesn't interfere with the loop, because the tasks_client_property has alredy been expanded
	set tasks_client_property [lreplace $tasks_client_property $counter $counter [array get test_task]]
    }
    incr counter
}


ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect "tasks"



