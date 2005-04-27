ad_page_contract {
    Make a copy of a process. Like making a new version.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
} -properties {
    context
    export_vars
    pretty_name
    new_workflow_key
    new_table_name
    new_workflow_pretty_name
    new_workflow_pretty_plural
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Copy process"]


db_1row pretty_names {
    select pretty_name, pretty_plural
    from acs_object_types
    where object_type = :workflow_key
}

# try to strip off the _wf ending.
if { ![regexp {^(.*)_wf$} $workflow_key match workflow_short_key] } {
    set workflow_short_key $workflow_key
}
    
set new_workflow_key [wf_make_unique -maxlen 30 \
	-taken_names [db_list object_types "select object_type from acs_object_types"] \
	$workflow_short_key "_wf"]

set new_table_name [wf_make_unique -maxlen 30 \
	-taken_names [db_tables] \
	$new_workflow_key "_cases"]

set new_workflow_pretty_name [wf_make_unique -maxlen 100 \
	-taken_names [db_list pretty_names "select pretty_name from acs_object_types"] \
	$pretty_name ""]

set new_workflow_pretty_plural [wf_make_unique -maxlen 100 \
	-taken_names [db_list pretty_plural_names "select pretty_plural from acs_object_types"] \
	$pretty_plural ""]

set export_vars [export_vars -form {workflow_key new_workflow_key new_table_name new_workflow_pretty_plural}]


ad_return_template



