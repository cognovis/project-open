# /packages/acs-workflow/www/case-assignment-set-2.tcl
ad_page_contract {
     Set case assignments for a role.
    
     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 14:50:50 2001
     @cvs-id $Id$
} {
    case_id:integer
    role_key
    {return_url:optional "case?[export_vars -url {case_id}]"}
    {assignments:multiple,integer {}}
    cancel:optional
}

if { ![info exists cancel] || [empty_string_p $cancel] } {

    # Don't update assignments if user hit cancel

    wf_case_set_manual_assignments \
	    -case_id $case_id \
	    -role_key $role_key \
	    -party_id_list $assignments
}

ad_returnredirect $return_url