ad_page_contract {
    Displays information about a case.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 18 August 2000
    @cvs-id $Id$
} {
    case_id:integer,notnull
} -properties {
    case:onerow
    context
    actions:multirow
    return_url
}

set return_url "[ns_conn url]?[export_vars -url {case_id}]"

db_1row case_info {
    select case_id, 
           acs_object.name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id
} -column_array case
set case(debug_url) "admin/case-debug?[export_vars -url {case_id}]"

set workflow_key $case(workflow_key)

set context [list "$case(object_name) case"]

template::multirow create actions url title
switch $case(state) {
    active {
	template::multirow append actions "case-state-change?[export_vars -url {case_id {action suspend}}]" "suspend"
	template::multirow append actions "case-state-change?[export_vars -url {case_id {action cancel}}]" "cancel"
    }
    suspended {
	template::multirow append actions "case-state-change?[export_url_vars case_id]&action=resume" "resume"
	template::multirow append actions "case-state-change?[export_url_vars case_id]&action=cancel" "cancel"
    }
    canceled {
	template::multirow append actions "case-state-change?[export_url_vars case_id]&action=resume" "resume"
    }
}

ad_return_template









