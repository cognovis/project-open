ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    assigned_transition_key:notnull
    assigning_transition_key:notnull
} -validate {
    tasks_exists -requires { assigning_transition_key:notnull assigned_transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]
	wf_wizard_massage_tasks $tasks_client_property tasks task
	if { ![info exists task($assigning_transition_key,transition_key)] } {
	    ad_complain "Invalid assigning task"
	} 
	if { ![info exists task($assigned_transition_key,transition_key)] } {
	    ad_complain "Invalid assigned task"
	} 
    }
    tasks_in_order -requires { tasks_exists } {
	set assigning_index [lsearch -exact $tasks $assigning_transition_key]
	set assigned_index [lsearch -exact $tasks $assigned_transition_key]
	if { $assigning_index > $assigned_index } {
	    ad_complain "You can't have a task doing assignment for a prior task"
	}
    }
}

array set edit_task [lindex $tasks_client_property $assigned_index]

set edit_task(assigning_transition_key) $assigning_transition_key

set tasks_client_property [lreplace $tasks_client_property $assigned_index $assigned_index [array get edit_task]]

ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect assignments
