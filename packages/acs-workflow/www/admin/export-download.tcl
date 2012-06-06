ad_page_contract {
    Export the definition of a workflow as a SQL script.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
} {
    workflow_key
    {context_key "default"}
}

ns_return 200 text/sql [wf_export_workflow -context_key $context_key $workflow_key]

