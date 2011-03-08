ad_page_contract {} {
    workflow_key
    context_key
    role_key
    party_id
    return_url
} 

db_dml static_assignment_delete {
    delete
    from   wf_context_assignments
    where  workflow_key = :workflow_key
    and    context_key = :context_key
    and    role_key = :role_key
    and    party_id = :party_id
} 

ad_returnredirect $return_url

