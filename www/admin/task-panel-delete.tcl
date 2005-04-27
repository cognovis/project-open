ad_page_contract {
    Delete the panel.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    transition_key:notnull
    context_key:notnull
    sort_order:notnull,integer
    {return_url "task-panels?[export_vars -url { workflow_key transition_key context_key }]"}
}

db_dml panel_delete {
    delete from wf_context_task_panels
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    context_key = :context_key
    and    sort_order = :sort_order
}

ad_returnredirect $return_url
