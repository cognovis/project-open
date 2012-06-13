# /packages/acs-workflow/www/admin/workflow-roles.tcl
ad_page_contract {
     Display roles for a workflow

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 09:38:08 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
} -properties {
    workflow:onerow
    context
    workflow_roles:multirow
} -validate {
    workflow_exists -requires {workflow_key} {
	if { 0 == [db_string workflow_exists "
	select count(*) from wf_workflows 
	where workflow_key = :workflow_key"] } {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
}

set return_url "[ns_conn url]?[export_vars -url {workflow_key}]"

db_1row workflow {
    select w.workflow_key, 
           t.pretty_name
    from   wf_workflows w, 
           acs_object_types t 
    where  w.workflow_key = :workflow_key 
    and    w.workflow_key = t.object_type
} -column_array workflow

set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow(pretty_name)"] "Workflow Roles"]

ad_return_template
