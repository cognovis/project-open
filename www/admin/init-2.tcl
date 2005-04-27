ad_page_contract {
    Hack to initialize a new case.
} {
    workflow_key
    {context_key "default"}
    object_id:integer
} 

wf_case_new $workflow_key $context_key $object_id

ad_returnredirect "workflow?[export_url_vars workflow_key]"
