ad_page_contract {
    Export the definition of a workflow as a SQL script.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
} {
    workflow_key
    {context_key "default"}
    {format "view"}
} -properties {
    context
    sql_script
    format
    return_url
    message
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Export process"]

set message {}

set sql [wf_export_workflow -context_key $context_key $workflow_key]

if { [string equal $format "save"] } {

    set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow' and rownum=1}]
    set tmp_path [ad_parameter -package_id $package_id "tmp_path"]
    if { ![file isdirectory $tmp_path] } {
	return -code error "Parameter acs-workflow.tmp_path points to a non-existing directory: $tmp_path"
    }
    
    set file_name "$tmp_path/workflow-$workflow_key-create.sql"

    set fw [open $file_name "w"]
    puts $fw $sql
    close $fw
    
    set message "SQL script has been saved to file $file_name on the server."
}

set sql_script [ad_quotehtml $sql]

ad_return_template
