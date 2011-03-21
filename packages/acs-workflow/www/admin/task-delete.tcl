ad_page_contract {
    Delete task.

    @author Lars Pind (lars@pinds.com)
    @creation-date Sep 2000
    @cvs-id $Id: task-delete.tcl,v 1.1 2005/04/27 22:51:00 cvs Exp $
} {
    workflow_key
    transition_key
    {return_url "define?[export_url_vars workflow_key]"}
}

wf_delete_transition \
	-workflow_key $workflow_key \
	-transition_key $transition_key

ad_returnredirect $return_url

