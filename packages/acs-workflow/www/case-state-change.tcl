ad_page_contract {
    Change the state of a case

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 August, 2000
    @cvs-id $Id$
} {
    case_id:integer
    return_url:optional
    action
} -validate {
    action_allowed -requires { action } {
	if { [lsearch -exact { suspend resume cancel } $action] == -1 } {
	    ad_complain "Action must be either 'suspend', 'resume' or 'cancel'"
	}
    }
}

switch $action {
    suspend {
	wf_case_suspend $case_id
    } 
    resume { 
	wf_case_resume $case_id
    } 
    cancel {
	wf_case_cancel $case_id
    }
}

if { ![info exists return_url] } {
    set return_url case?[export_url_vars case_id]
}

ad_returnredirect $return_url