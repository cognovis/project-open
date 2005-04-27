ad_page_contract {
    Move up one task panel in the sort_key sequence.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    context_key
    sort_key
}

db_transaction {
    set prior_sort_key [db_string prior_sort_key { 
	select max(sort_key) 
	from   wf_context_task_panels
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
	and    sort_key < :sort_key
    }]

    db_dml panel_move_up {
	update wf_context_task_panels
	set    sort_key = decode(sort_key, :sort_key, :prior_sort_key, :prior_sort_key, :sort_key)
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
	and    sort_key in (:sort_key, :prior_sort_key)
    }
}

ad_returnredirect "task-panels?[export_vars -url { workflow_key transition_key context_key }]"
