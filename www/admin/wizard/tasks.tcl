ad_page_contract {
    Second stage of workflow definition.
    Add tasks.

    @author Matthew Burke (mburke@arsdigita.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
} -properties {
    workflow_name
    tasks:multirow
}

set workflow_name [ad_get_client_property wf workflow_name]

if { [empty_string_p $workflow_name] } {
    ad_returnredirect ""
    ad_script_abort
}

wf_wizard_massage_tasks [ad_get_client_property wf tasks] "" "" tasks

set context [list [list "" "Simple Process Wizard"] "Tasks"]

ad_return_template