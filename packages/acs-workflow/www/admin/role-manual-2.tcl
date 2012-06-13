ad_page_contract {
    Make role manually assigned. 
    
    @author Lars Pind (lars@pinds.com)
    @creation-date Feb 27, 2001
    @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    transition_key:notnull
    {return_url "workflow?[export_vars -url {workflow_key {tab roles}}]"}
    cancel:optional
}



wf_add_trans_role_assign_map \
	-workflow_key $workflow_key \
	-transition_key $transition_key \
	-assign_role_key $role_key

ad_returnredirect $return_url

