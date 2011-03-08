ad_page_contract {
    Add task.
} {
    workflow_key:notnull
    transition_name:notnull
    role_key:allhtml
    trigger_type:notnull
    {estimated_minutes:integer ""}
    {instructions ""}
    {context_key "default"}
    {return_url ""}
    cancel:optional
} -validate {
    transition_name_unique -requires { workflow_key:notnull transition_name:notnull } {
	set num_rows [db_string num_transitions {
	    select count(*) 
	    from   wf_transitions
	    where  workflow_key = :workflow_key
	    and    transition_name = :transition_name
	}]

        if { $num_rows > 0 } {
	    ad_complain "There is already a task with this name"
	}
    }

    trigger_type_legal -requires { trigger_type } {
	set trigger_type [string tolower $trigger_type]
	if { [lsearch -exact { user automatic message time } $trigger_type] == -1 } {
	    ad_complain "Trigger type must be one of user, automatic, message or time."
	}
    }
}

if { [info exists cancel] && ![empty_string_p $cancel] } {
    # User hit cancel
    if { [empty_string_p $return_url] } {
	set return_url "define?[export_vars -url {workflow_key}]"
    }
    ad_returnredirect $return_url
    ad_script_abort
}

set create_new_role_p 0
if { [string equal $role_key "<new>"] } {
    set role_key ""
    set create_new_role_p 1
}

set transition_key [wf_add_transition \
	-workflow_key $workflow_key \
	-transition_name $transition_name \
	-role_key $role_key \
	-trigger_type $trigger_type \
	-estimated_minutes $estimated_minutes \
	-instructions $instructions]

if { [empty_string_p $return_url] } {
    set return_url "define?[export_vars -url {workflow_key transition_key}]"
}

if { $create_new_role_p } {
    set return_url "task-edit?[export_vars -url {workflow_key transition_key context_key return_url {new_role_p 1}}]"
}
    
ad_returnredirect $return_url