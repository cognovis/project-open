ad_page_contract {
    Move role down.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date Feb 27, 2001
    @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    {return_url "workflow?[export_vars -url {workflow_key {tab roles}}]"}
}

wf_move_role_down \
	-workflow_key $workflow_key \
	-role_key $role_key

ad_returnredirect $return_url

