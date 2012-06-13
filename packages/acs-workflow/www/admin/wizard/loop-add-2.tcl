ad_page_contract {

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    from_transition_key:notnull
    to_transition_key:notnull
    question:notnull,trim
    answer:notnull,trim
} -validate {
    tasks_exists -requires { from_transition_key:notnull to_transition_key:notnull } {
	set tasks_client_property [ad_get_client_property wf tasks]
	wf_wizard_massage_tasks $tasks_client_property tasks task
	if { ![info exists task($from_transition_key,transition_key)] } {
	    ad_complain "Invalid task to loop from"
	} 
	if { ![info exists task($to_transition_key,transition_key)] } {
	    ad_complain "Invalid task to loop to"
	} 
    }
    tasks_in_order -requires { tasks_exists } {
	set from_index [lsearch -exact $tasks $from_transition_key]
	set to_index [lsearch -exact $tasks $to_transition_key]
	if { $to_index > $from_index } {
	    ad_complain "You can only loop backwards in the process"
	}
    }
    answer_is_t_or_f -requires { answer:notnull } {
	if { ![string equal $answer t] && ![string equal $answer f] } {
	    ad_complain "Answer must be t or f"
	}
    }
}

# Remove trailing question marks
set question [string trimright $question "?"]

array set the_task [lindex $tasks_client_property $from_index]
set the_task(loop_to_transition_key) $to_transition_key
set the_task(loop_question) $question
set the_task(loop_answer) $answer
set tasks_client_property [lreplace $tasks_client_property $from_index $from_index [array get the_task]]

ad_set_client_property -persistent t wf tasks $tasks_client_property

ad_returnredirect loops