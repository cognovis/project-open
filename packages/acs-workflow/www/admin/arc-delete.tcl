ad_page_contract {
    delete an arc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 1 October 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    place_key
    direction
    {return_url "define?[export_url_vars workflow_key transition_key]"}
}

wf_delete_arc \
	-workflow_key $workflow_key \
	-transition_key $transition_key \
	-place_key $place_key \
	-direction $direction

ad_returnredirect $return_url
