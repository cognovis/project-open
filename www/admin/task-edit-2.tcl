ad_page_contract {
    Edit task.
} {
    workflow_key:notnull
    transition_key:notnull
    transition_name:notnull
    trigger_type:notnull
    role_key:allhtml,optional
    role_name:optional
    estimated_minutes:integer,optional
    instructions:allhtml,optional
    {return_url "define?[export_vars -url {workflow_key transition_key}]"}
    cancel:optional
    {context_key "default"}
}

if { [info exists cancel] && ![empty_string_p $cancel] } {
    # User hit cancel
    ad_returnredirect $return_url
    ad_script_abort
}

db_transaction {
    if { ![info exists role_key] } {
        set role_key [wf_add_role -workflow_key $workflow_key -role_name $role_name]
    }
    
    if { ![string equal $role_key "<new>"] } {
	db_dml transition_update {
	    update wf_transitions
	    set    transition_name = :transition_name,
		   trigger_type = :trigger_type,
		   role_key = :role_key
	    where  workflow_key = :workflow_key
	    and    transition_key = :transition_key
	}
    } else {
	db_dml transition_update {
	    update wf_transitions
	    set    transition_name = :transition_name,
		   trigger_type = :trigger_type
	    where  workflow_key = :workflow_key
	    and    transition_key = :transition_key
	}
    }
    
    if { [info exists estimated_minutes] || [info exists instructions] } {
	set num_rows [db_string num_rows "select count(*) from wf_context_transition_info where workflow_key = :workflow_key and transition_key = :transition_key and context_key = 'default'"]
    
	if { $num_rows == 0 } {
	    db_dml insert_estimated_minmutes {
		insert into wf_context_transition_info
		(workflow_key, transition_key, context_key, estimated_minutes, instructions)
		values (:workflow_key, :transition_key, 'default', :estimated_minutes, :instructions)
	    }
	} else {
	    db_dml update_estimated_minutes {
		update wf_context_transition_info 
		   set estimated_minutes = :estimated_minutes,
		       instructions = :instructions
		 where workflow_key = :workflow_key  
		   and transition_key = :transition_key 
		   and context_key = 'default'
	    }
	}
    }   
}

wf_workflow_changed $workflow_key

if { [string equal $role_key "<new>"] } {
    set return_url "task-edit?[export_vars -url {workflow_key transition_key context_key return_url {new_role_p 1}}]"
}



ad_returnredirect $return_url

