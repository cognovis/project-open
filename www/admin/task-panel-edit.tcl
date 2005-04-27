ad_page_contract {
    Edit a task panel.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    transition_key:notnull
    {context_key "default"}
    sort_order:notnull,integer
    return_url:optional
} -properties {
    context
    transition_name
    panel:onerow
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

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Edit panel"]

db_1row panel {
    select p.header,
           p.template_url,
           p.overrides_action_p,
           p.only_display_when_started_p
    from   wf_context_task_panels p
    where  p.workflow_key = :workflow_key
    and    p.transition_key = :transition_key
    and    p.context_key = :context_key
    and    p.sort_order = :sort_order
} -column_array panel

set panel(export_vars) [export_vars -form { workflow_key transition_key context_key sort_order return_url }]

ad_return_template



