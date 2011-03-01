ad_page_contract {
    Returns a graphviz-dot file representation of the workflow.

    This page is for debugging purposes only.
} {
    workflow_key
}

set workflow_info [wf_get_workflow_net $workflow_key]
array set workflow $workflow_info
db_release_unused_handles

set dot_text [wf_generate_dot_representation $workflow_info]

ns_return 200 text/plain $dot_text
