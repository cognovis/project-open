ad_page_contract {
    Export the definition of a workflow as a SQL script.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
} {
    workflow_key
    {context_key "default"}
} -properties {
    context
    download_url
    view_url
    textarea_url
    save_url
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Export process"]

set download_url "export-download?[export_vars -url {workflow_key context_key}]"
set view_url "export-2?[export_vars -url {workflow_key context_key {format "view"}}]"
set textarea_url "export-2?[export_vars -url {workflow_key context_key {format "textarea"}}]"
set save_url "export-2?[export_vars -url {workflow_key context_key {format "save"}}]"

ad_return_template
