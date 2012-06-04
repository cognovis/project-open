ad_page_contract {
    Third stage of simple process wizard.
    Add loops.

    @author Matthew Burke (mburke@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} -properties {
    workflow_name
    tasks:multirow
    loop_from_task_name
    loop_to_task_name
    loop_next_pretty
}

set workflow_name [ad_quotehtml [ad_get_client_property wf workflow_name]]

if { [empty_string_p $workflow_name] } {
    ad_returnredirect ""
    ad_script_abort
}

wf_wizard_massage_tasks [ad_get_client_property wf tasks] task_list task tasks

set context [list [list "" "Simple Process Wizard"] "Loops"]

set loop_from_task_name {}
set loop_to_task_name {}
set loop_next_pretty {}

if { [llength $task_list] == 1 } {
    
    set the_transition_key [lindex $task_list 0]

    set loop_from_task_name [ad_quotehtml $task($the_transition_key,task_name)]

} else {
    switch [llength $task_list] {
	2 {
	    set from_idx 1
	    set to_idx 0
	    set next_idx -1
	}
	3 { 
	    set from_idx 1
	    set to_idx 0
	    set next_idx [expr $from_idx + 1]
	}
	default {
	    set from_idx [expr [llength $task_list]-2]
	    set to_idx 1
	    set next_idx [expr $from_idx + 1]
	}
    }
    
    set from_transition_key [lindex $task_list $from_idx]
    set to_transition_key [lindex $task_list $to_idx]
    if { $next_idx != -1 } {
	set next_transition_key [lindex $task_list $next_idx]
	set next_pretty "'$task($next_transition_key,task_name)'"
    } else {
	set next_pretty "the end of the process"
    }

    set loop_from_task_name [ad_quotehtml $task($from_transition_key,task_name)]
    set loop_to_task_name [ad_quotehtml $task($to_transition_key,task_name)]
    set loop_next_pretty [ad_quotehtml $next_pretty]
}

ad_return_template