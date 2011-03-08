ad_page_contract {
    Add another attribute to be set by a task.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id: task-attribute-add.tcl,v 1.1 2005/04/27 22:51:00 cvs Exp $
} {
    workflow_key
    transition_key
    attribute_id
    return_url
}

db_dml transition_attribute_add {
    insert into wf_transition_attribute_map (workflow_key, transition_key, sort_order, attribute_id)
    select :workflow_key, :transition_key, nvl(max(sort_order)+1,1), :attribute_id
    from wf_transition_attribute_map
    where workflow_key = :workflow_key
    and   transition_key = :transition_key
}

ad_returnredirect $return_url
