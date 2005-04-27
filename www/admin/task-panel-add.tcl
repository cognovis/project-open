ad_page_contract {
    Add a task panel.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    transition_key:notnull
    {context_key "default"}
    return_url:optional
} -properties {
    context
    transition_name
    export_vars
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

set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow_name"]  "Add panel"]

set export_vars [export_vars -form { workflow_key transition_key context_key return_url}]

ad_return_template



