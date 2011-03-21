ad_page_contract {} {
    workflow_key
    context_key
    role_key
    party_id:integer
    return_url 
} -errors {
    party_id:integer "Please select someone to assign"
}

db_dml static_assignment_add {
    insert into wf_context_assignments
        (workflow_key, context_key, role_key, party_id)
    values
        (:workflow_key, :context_key, :role_key, :party_id)
}

ad_returnredirect $return_url
