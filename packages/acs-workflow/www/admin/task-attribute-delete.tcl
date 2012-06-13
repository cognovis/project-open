ad_page_contract {
    The attribute should not be set by the transition.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    attribute_id
    return_url
}

db_dml panel_delete {
    delete from wf_transition_attribute_map
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    attribute_id = :attribute_id
}

ad_returnredirect $return_url
