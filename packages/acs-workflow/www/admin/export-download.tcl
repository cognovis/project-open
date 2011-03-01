ad_page_contract {
    Export the definition of a workflow as a SQL script.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id: export-download.tcl,v 1.1 2005/04/27 22:51:00 cvs Exp $
} {
    workflow_key
    {context_key "default"}
}

ns_return 200 text/sql [wf_export_workflow -context_key $context_key $workflow_key]

