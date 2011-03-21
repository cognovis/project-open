ad_page_contract {
    Edit place.
} {
    workflow_key
    place_key
    return_url:optional
} -properties {
    place_name
    export_vars
    special_widget
}    

db_1row place_info {
    select p.place_name,
           ot.pretty_name as workflow_name
    from   wf_places p, acs_object_types ot
    where  p.place_key = :place_key
    and    p.workflow_key = :workflow_key
    and    ot.object_type = p.workflow_key
}

set place_name [ad_quotehtml $place_name]

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_url_vars workflow_key]" "Edit process"] "Edit place"]

set export_vars [export_form_vars workflow_key place_key return_url]

ad_return_template