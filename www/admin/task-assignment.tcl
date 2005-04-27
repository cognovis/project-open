ad_page_contract {
    Manage assignment of a transition.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    {return_url ""}
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    transition_key
    workflow_key
    transition_name
    context
    assigned_by_this:multirow
    to_be_assigned_by_this:multirow
    assign_url
    assign_export_vars
    return_url
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

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_vars -url {workflow_key transition_key}]" "Edit process"] "Assignments by $transition_name"]

db_multirow assigned_by_this assigned_by_this {
    select r.role_name,
           r.role_key,
           '' as delete_url
    from   wf_transition_role_assign_map m, 
           wf_roles r
    where  m.workflow_key = :workflow_key
    and    m.transition_key = :transition_key
    and    r.workflow_key = m.workflow_key
    and    r.role_key = m.assign_role_key
} { 
    set vars {
	workflow_key
	transition_key 
	role_key 
	{return_url "task-assignment?[export_vars -url {workflow_key transition_key return_url}]"}
    }
    set delete_url "task-assignment-delete?[export_vars -url $vars]"
}

db_multirow to_be_assigned_by_this to_be_assigned_by_this {
    select r.role_name,
           r.role_key
    from   wf_roles r
    where  r.workflow_key = :workflow_key
    and    r.role_key != (select role_key from wf_transitions t where workflow_key = :workflow_key and transition_key = :transition_key)
    and    not exists (select 1 from wf_transition_role_assign_map m
                       where  m.workflow_key = :workflow_key
                       and    m.transition_key = :transition_key
                       and    m.assign_role_key = r.role_key)
}
            
set assign_url "task-assignment-add"
set vars {
    workflow_key 
    transition_key 
    {return_url "task-assignment?[export_vars -url {workflow_key transition_key return_url}]"}
}
set assign_export_vars [export_vars -form $vars]

set return_url "define?[export_vars -url {workflow_key transition_key}]"

ad_return_template
