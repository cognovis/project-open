ad_page_contract {
    Make a copy of a process. Like making a new version.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    new_workflow_key
    new_table_name
    new_workflow_pretty_name
    new_workflow_pretty_plural
} -validate {
    workflow_key_un -requires { new_workflow_key } {
	if { [lsearch -exact $new_workflow_key [db_list object_types "select object_type from acs_object_types"]] != -1 } {
	    ad_complain "Workflow_key is not unique."
	}
    }
    table_name_un -requires { new_table_name } {
	if { [lsearch $new_table_name [db_tables]] != -1 } {
	    ad_complain "Table name is not unique"
	}
    }
    pretty_name_un -requires { new_workflow_pretty_name } {
	if { [lsearch $new_workflow_pretty_name [db_list pretty_names "select pretty_name from acs_object_types"]] != -1 } {
	    ad_complain "Name is not unique"
	}
    }
    pretty_plural_un -requires { new_workflow_pretty_plural } {
	if { [lsearch $new_workflow_pretty_plural [db_list pretty_names "select pretty_plural from acs_object_types"]] != -1 } {
	    ad_complain "Plural name is not unique"
	}
    }
}

set sql [wf_export_workflow \
	-new_workflow_key $new_workflow_key \
	-new_table_name $new_table_name \
	-new_workflow_pretty_name $new_workflow_pretty_name \
	-new_workflow_pretty_plural $new_workflow_pretty_plural \
	$workflow_key]

set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow' and rownum=1}]
set tmp_path [ad_parameter -package_id $package_id "tmp_path"]
if { ![file isdirectory $tmp_path] } {
    return -code error "Parameter acs-workflow.tmp_path points to a non-existing directory: $tmp_path"
}

set file_name "$tmp_path/workflow-$workflow_key-to-$new_workflow_key-copy.sql"

set fw [open $file_name "w"]
puts $fw $sql
close $fw

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

ReturnHeaders
ns_write "[ad_header "Copying Process..."]
<h2>Copying Process...</h2>
[ad_context_bar [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Copy process"]
<hr>

<pre>
"

db_source_sql_file $file_name

ns_write "
</pre>

<p>

The process has been copied.

<p>

Go to <a href=\"workflow?[export_vars -url {{workflow_key $new_workflow_key}}]\">the administration page</a> for your new process.

[ad_footer]
"

