ad_page_contract {
    Edit place.
} {
    workflow_key
    place_key
    place_name
    {sort_order:integer ""}
    {return_url "define?[export_url_vars workflow_key place_key]"}
}

db_dml place_update {
    update wf_places
    set    place_name = :place_name
    where  workflow_key = :workflow_key
    and    place_key = :place_key
}

wf_workflow_changed $workflow_key

ad_returnredirect $return_url
