# /packages/acs-workflow/www/case-deadline-set-2.tcl
ad_page_contract {
     Sets deadline for case transition.

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Mon Jan 15 10:11:07 2001
     @cvs-id $Id$
} {
    case_id:integer
    transition_key
    {return_url:optional "case?[export_vars -url {case_id}]"}
    deadline:array,date
    cancel:optional
}

if { ![info exists cancel] || [empty_string_p $cancel] } {

    # Only set deadline if the user didn't hit cancel
    
    wf_case_set_case_deadline \
	    -case_id $case_id \
	    -transition_key $transition_key \
	    -deadline $deadline(date)
}
    
ad_returnredirect $return_url
