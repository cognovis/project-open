ad_page_contract {
    Move up one attribute in the sort_order sequence.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    attribute_id
    return_url
}

db_transaction {
    set sql {
	select sort_order from wf_transition_attribute_map m2
	where  m2.workflow_key = :workflow_key
	and    m2.transition_key = :transition_key
	and    m2.attribute_id = :attribute_id
    }

    set sort_order [db_string this_sort_order $sql]

    set sql { 
	select max(sort_order)
	from   wf_transition_attribute_map
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    sort_order < :sort_order
    }

    set prior_sort_order [db_string prior_sort_order $sql]

    db_dml attribute_move_up {
	update wf_transition_attribute_map
	set    sort_order = decode(sort_order, :sort_order, :prior_sort_order, :prior_sort_order, :sort_order)
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    sort_order in (:sort_order, :prior_sort_order)
    }
}

ad_returnredirect $return_url
