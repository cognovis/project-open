ad_page_contract {
    Edit arc.
} {
    workflow_key:notnull
    transition_key:notnull
    place_key:notnull
    direction:notnull
    guard_callback
    guard_custom_arg
    guard_description
    {return_url "define?[export_url_vars workflow_key transition_key]"}
}

db_dml arc_update {
    update wf_arcs
    set    guard_callback = :guard_callback,
           guard_custom_arg = :guard_custom_arg,
           guard_description = :guard_description
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    place_key = :place_key
    and    direction = :direction
}

wf_workflow_changed $workflow_key

ad_returnredirect $return_url
