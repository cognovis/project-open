ad_page_contract {
    Edit name of workflow.
} {
    workflow_key:notnull
    return_url:optional
} -properties {
    context
    export_vars
    workflow_name
    description
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name, w.description
    from   acs_object_types ot, wf_workflows w
    where  ot.object_type = w.workflow_key
    and    w.workflow_key = :workflow_key
}



set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Edit name"]

set export_vars [export_form_vars workflow_key return_url]

set workflow_name [ad_quotehtml $workflow_name]
set description [ad_quotehtml $description]

ad_return_template 
