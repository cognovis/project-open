ad_page_contract {
    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    task_name:trim,nohtml,notnull
    task_time:integer
} -validate {
    task_name_unique -requires { task_name:notnull } {
	set tasks [ad_get_client_property wf tasks]
	for { set i 0 } { $i < [llength $tasks] } { incr i } {
	    array set test_task [lindex $tasks $i]
	    if { [string equal $task_name $test_task(task_name)] } {
		ad_complain "You already have a task with this name."
	    }
	}
    }
}

set tasks [ad_get_client_property wf tasks]

set task(task_name) $task_name
set task(transition_key) [wf_name_to_key $task_name]
set task(task_time) $task_time
set task(loop_to_transition_key) {}
set task(assigning_transition_key) {}

lappend tasks [array get task]

ad_set_client_property -persistent t wf tasks $tasks

ad_returnredirect "tasks"



