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


db_1row workflow_and_transition_name {}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Edit panel"]

db_1row panel {} -column_array panel

set panel(export_vars) [export_vars -form { workflow_key transition_key context_key sort_order return_url }]

ad_return_template



