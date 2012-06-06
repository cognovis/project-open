# /packages/acs-workflow/www/admin/assign-transition-role-2.tcl
ad_page_contract {
     Add assignment of a transition to a role.

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 11:16:04 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    transition_key:notnull
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

db_dml assign_transition_role {
    update wf_transitions set role_key = :role_key
    where workflow_key = :workflow_key
    and transition_key = :transition_key
}

ad_returnredirect "workflow-roles?[export_vars -url {workflow_key}]"
