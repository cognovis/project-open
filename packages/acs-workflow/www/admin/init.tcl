ad_page_contract {
    This page should go away and the applications take care of this themselves.
    Or at least it should be cleaned up.
} {
    workflow_key
} -properties {
    context
    export_vars
    contexts:multirow
    objects:multirow
}


db_multirow contexts context {
    select context_key, context_name, '' as selected
    from wf_contexts 
    order by context_name 
} { 
    if { [string equal $context_key "default"] } { 
	set selected "SELECTED"
    }
}

db_multirow objects object {
    select object_id, acs_object.name(object_id) as name from acs_objects order by name
} 

set workflow_name [db_string workflow_name "select pretty_name from acs_object_types where object_type = :workflow_key"]

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Start case"]

set export_vars [export_form_vars workflow_key]

ad_return_template



