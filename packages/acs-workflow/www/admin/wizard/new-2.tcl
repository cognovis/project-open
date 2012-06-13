ad_page_contract {
    Second stage of simple process wizard.
    Validate the name and description, stuff them into
    client properties and redirect to next stage.

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} {
    workflow_name:trim,nohtml,notnull
    description
} -errors {
    description {Please describe the process.}
    workflow_name:,notnull {You must enter a name for the process.}
}


ad_set_client_property -persistent t wf workflow_name $workflow_name
ad_set_client_property -persistent t wf workflow_description $description


ad_returnredirect "tasks"

