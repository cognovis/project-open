ad_page_contract {
    Task actions.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 19, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    {context_key "default"}
    {return_url ""}
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
}

db_1row workflow_and_transition_name {
    select ot.pretty_name as workflow_name,
           t.transition_name
    from   acs_object_types ot,
           wf_transitions t
    where  ot.object_type = :workflow_key
    and    t.workflow_key = ot.object_type
    and    t.transition_key = :transition_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_vars -url {workflow_key transition_key}]" "Edit process"] "Actions by $transition_name"]

set export_vars [ad_export_vars -form {workflow_key transition_key context_key return_url}]

set sql {
    select enable_callback,
	   enable_custom_arg,
	   fire_callback,
	   fire_custom_arg,
	   time_callback,
	   time_custom_arg,
	   deadline_callback,
	   deadline_custom_arg,
	   deadline_attribute_name,
	   hold_timeout_callback,
	   hold_timeout_custom_arg,
	   notification_callback,
	   notification_custom_arg,
	   unassigned_callback,
	   unassigned_custom_arg
    from   wf_context_transition_info
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    context_key = :context_key
}

if { ![db_0or1row callbacks $sql] } {
    foreach var { 
	enable_callback
	enable_custom_arg
	fire_callback
	fire_custom_arg
	assignment_callback
	assignment_custom_arg
	time_callback
	time_custom_arg
	deadline_callback
	deadline_custom_arg
	deadline_attribute_name
	hold_timeout_callback
	hold_timeout_custom_arg
	notification_callback
	notification_custom_arg
	unassigned_callback
	unassigned_custom_arg 
    } {
	set $var ""
    }
}

ad_return_template



