ad_page_contract {
    Fourth stage of simple process wizard.
    Add assignments.

    @author Matthew Burke (mburke@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} -properties {
    workflow_name
    context
    tasks:multirow
    tasks_with_options:multirow
}


set workflow_name [ad_quotehtml [ad_get_client_property wf workflow_name]]
wf_wizard_massage_tasks [ad_get_client_property wf tasks] task_list task tasks

set context [list [list "" "Simple Process Wizard"] "Assignments"]


# We massage the tasks into 'tasks_with_options", which is an outer-join style multirow,
# the outer join being the list of all prior tasks, so we can put them into an in-line
# select box.

template::multirow create tasks_with_options transition_key task_name \
	task_time \
	loop_to_transition_key loop_to_task_name loop_question loop_answer \
	assigning_transition_key assigning_task_name \
	assigning_task_num_option assigning_transition_key_option assigning_task_name_option

foreach transition_key $task_list {
    if { [string equal $transition_key [lindex $task_list 0]] } {
	# This is the first task
	template::multirow append tasks_with_options \
		$transition_key \
		$task($transition_key,task_name) \
		$task($transition_key,task_time) \
		$task($transition_key,loop_to_transition_key) \
		$task($task($transition_key,loop_to_transition_key),task_name) \
		$task($transition_key,loop_question) \
		$task($transition_key,loop_answer) \
		$task($transition_key,assigning_transition_key) \
		$task($task($transition_key,assigning_transition_key),task_name) \
		{} {} {}
	
    } else {
	# This is for all other tasks
	set counter 1
	foreach inner_transition_key $task_list {
	    if { [string equal $inner_transition_key $transition_key] } {
		break
	    }
	    template::multirow append tasks_with_options \
		    $transition_key \
		    $task($transition_key,task_name) \
		    $task($transition_key,task_time) \
		    $task($transition_key,loop_to_transition_key) \
		    $task($task($transition_key,loop_to_transition_key),task_name) \
		    $task($transition_key,loop_question) \
		    $task($transition_key,loop_answer) \
		    $task($transition_key,assigning_transition_key) \
		    $task($task($transition_key,assigning_transition_key),task_name) \
		    $counter $inner_transition_key \
		    $task($inner_transition_key,task_name)
	    incr counter
	}
    }
}

ad_return_template

