ad_page_contract {
    Delete role.

    @author Lars Pind (lars@pinds.com)
    @creation-date Sep 2000
    @cvs-id $Id: role-delete.tcl,v 1.1 2005/04/27 22:51:00 cvs Exp $
} {
    workflow_key
    role_key
    {return_url "define?[export_url_vars workflow_key]"}
}

wf_delete_role \
	-workflow_key $workflow_key \
	-role_key $role_key

ad_returnredirect $return_url

