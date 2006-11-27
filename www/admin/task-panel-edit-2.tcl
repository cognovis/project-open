ad_page_contract {
    Edit the panel.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    transition_key:notnull
    {context_key "default"}
    sort_order:notnull,integer
    header:notnull
    template_url:notnull
    overrides_action_p:notnull,boolean
    overrides_both_panels_p:notnull,boolean
    only_display_when_started_p:notnull,boolean
    {return_url "task-panels?[export_vars -url { workflow_key transition_key context_key }]"}
    cancel:optional
}

if { ![info exists cancel] || [empty_string_p $cancel] } {

    db_dml panel_update {}
}

ad_returnredirect $return_url
