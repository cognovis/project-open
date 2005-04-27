# /packages/acs-workflow/www/admin/assign-transition-role.tcl
ad_page_contract {
     Sets a transition's role.
    
     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 10:31:34 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
} -properties {
    workflow:onerow
    role:onerow
    available_transitions:multirow
    export_form_vars
} -validate {
    workflow_exists -requires {workflow_key} {
	if { 0 == [db_string workflow_exists "
	select count(*) from wf_workflows 
	where workflow_key = :workflow_key"] } {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
    role_exists -requires {role_key} {
	if { 0 == [db_string role_exists "
	select count(*) from wf_roles 
	where workflow_key = :workflow_key
        and role_key = :role_key"] } {
	    ad_complain "You seem to have specified a nonexistent role."
	}
    }
}

db_1row workflow {
    select w.workflow_key, 
           t.pretty_name
    from   wf_workflows w, 
           acs_object_types t 
    where  w.workflow_key = :workflow_key 
    and    w.workflow_key = t.object_type
} -column_array workflow

db_1row role {
    select role_name
    from wf_roles
    where workflow_key = :workflow_key
    and role_key = :role_key
} -column_array role

set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow(pretty_name)"] [list "workflow-roles?[export_vars -url {workflow_key}]" "Workflow Roles"] "Assign transition to $role(role_name)"]

db_multirow available_transitions workflow_transitions {
    select transition_name,
           transition_key
    from wf_transitions
    where workflow_key = :workflow_key
    and role_key is null
    order by sort_order
} {
}

set export_form_vars [export_vars -form {workflow_key role_key}]

ad_return_template
