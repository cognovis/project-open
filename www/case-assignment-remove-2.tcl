ad_page_contract {
    Remove manual assignment.

    @cvs-id $Id$
    @author Lars Pind (lars@pinds.com)
    @creation-date Feb 21, 2001
} {
    case_id:integer
    role_key
    party_id:integer
    {return_url "case?[export_vars -url {case_id}]"}
}

wf_case_remove_manual_assignment \
	-case_id $case_id \
	-role_key $role_key \
	-party_id $party_id 


ad_returnredirect $return_url
