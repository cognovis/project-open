ad_page_contract {
    Manage workflow task panels.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    {context_key "default"}
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    transition_key
    workflow_key
    transition_name
    context
    context_slider:multirow
    context_add_url
    panels:multirow
    panel_add_url
}

db_1row workflow_and_transition_name {
    select ot.pretty_name as workflow_name,
           t.transition_name
    from   acs_object_types ot,
           wf_transitions t
    where  ot.object_type = :workflow_key
    and    t.workflow_key = ot.object_type
    and    t.transition_key = :transition_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_vars -url {workflow_key transition_key}]" "Edit process"] "Panels for $transition_name"]

db_multirow context_slider context_slider {
    select context_key as context_key_from_db,
           context_name as title,
           '' as url,
           0 as selected_p
    from   wf_contexts
    order by context_name
} {
    if { [string equal $context_key $context_key_from_db] } {
        set selected_p 1
    }
    set url "task-panels?[export_vars -url { workflow_key transition_key {context_key $context_key_from_db} }]"
}
set context_add_url "context-add?[export_vars -url {workflow_key {return_url "task-panels?[export_vars -url {workflow_key transition_key context_key}]"}}]"

set count 0
db_multirow panels panels {
    select tp.sort_order,
           tp.header, 
           tp.template_url,
           '' as edit_url,
           '' as delete_url,
           '' as move_up_url
    from   wf_context_task_panels tp
    where  tp.context_key = :context_key
    and    tp.workflow_key = :workflow_key
    and    tp.transition_key = :transition_key
    order by sort_order
} {
    incr count
    set edit_url "task-panel-edit?[export_vars -url { workflow_key transition_key context_key sort_order } ]"
    set delete_url "task-panel-delete?[export_vars -url { workflow_key transition_key context_key sort_order } ]"
    if { $count > 1 } {
	set move_up_url "task-panel-move-up?[export_vars -url { workflow_key transition_key context_key sort_order } ]"
    }
}

set panel_add_url "task-panel-add?[export_vars -url { workflow_key transition_key context_key }]"

ad_return_template

