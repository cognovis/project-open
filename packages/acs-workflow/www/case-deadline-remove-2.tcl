# /packages/acs-workflow/www/case-deadline-remove-2.tcl
ad_page_contract {
     Sets deadline for case transition.

     @author Lars Pind (lars@pinds.com)
     @creation-date Feb 21, 2001
     @cvs-id $Id$
} {
    case_id:integer
    transition_key
    {return_url:optional "case?[export_vars -url {case_id}]"}
}

wf_case_remove_case_deadline \
	-case_id $case_id \
	-transition_key $transition_key

ad_returnredirect $return_url
