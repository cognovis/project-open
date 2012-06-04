ad_page_contract {
    Move a task up one step.

    @author Lars Pind (lars@pinds.com)
    @creation-date 28 September 2000
    @cvs-id $Id$
} {
    transition_key:trim,notnull
} -validate {
    task_exists -requires { transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]
	wf_wizard_massage_tasks $tasks_client_property tasks task
	if { ![info exists task($transition_key,transition_key)] } {
	    ad_complain "Invalid task"
	} 
    }
    check_valid_move -requires { task_exists } {
	set move_index [lsearch -exact $tasks $transition_key]
	if { $move_index == 0 } {
	    ad_complain "Can't move the first task up"
	}
	set replace_index [expr $move_index-1]
    }
}


array set move_task [lindex $tasks_client_property $move_index]
array set replace_task [lindex $tasks_client_property $replace_index]

set move_transition_key $transition_key
set replace_transition_key [lindex $tasks $replace_index]

# Check if the one we're moving has a loop to the one we're replacing
if { [string equal $move_task(loop_to_transition_key) $replace_transition_key] } {
    set move_task(loop_to_transition_key) {}
    set move_task(loop_question) {}
    set move_task(loop_answer) {}
}

# Check if the one we're moving was being assigned by the one we're replacing
if { [string equal $move_task(assigning_transition_key) $replace_transition_key] } {
    set move_task(assigning_transition_key) {}
}

# Update the client property entry for move_task to reflect the loop/assignment changes just made, if any
set tasks_client_property [lreplace $tasks_client_property $move_index $move_index [array get move_task]]

ad_set_client_property -persistent t wf tasks \
	[lreplace $tasks_client_property $replace_index $move_index \
	[lindex $tasks_client_property $move_index] [lindex $tasks_client_property $replace_index]]

ad_returnredirect tasks