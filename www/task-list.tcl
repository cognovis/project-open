ad_page_contract {} {
} -properties {
    task_list
}

if { ![info exist date_format] || [empty_string_p $date_format] } {
    set date_format "Mon fmDDfm, YYYY HH24:MI:SS"
}
if { ![info exists type] || [empty_string_p $type] } {
    set type enabled
}

if { ![info exists object_id] || [empty_string_p $object_id] } {
    set object_id ""
}

if { ![info exists package_url] || [empty_string_p $package_url] } {
    set package_url [ad_conn package_url]
}




# DRB: setting return_url to point explicitly at ourselves will cause
# custom workflow action panels to return to the right place whether
# they're called from the workflow UI or a custom package UI.

if { ![info exists return_url] || [empty_string_p $return_url] } {
    set return_url [ad_conn url]
}

if { ![string equal $type "enabled"] && ![string equal $type "own"] \
    && ![string equal $type "unassigned"] } {
    ad_return_error "Bad type" "Unrecognized type: Type can be 'enabled' or 'own'"
    ad_script_abort
}

set user_id [ad_get_user_id]

set select [db_map select_list]

set from {
    {wf_cases c} 
    {acs_objects o} 
    {acs_object_types ot}
    {acs_object_types wft}
}
set where {
    {c.case_id = t.case_id} 
    {c.object_id = o.object_id} 
    {ot.object_type = o.object_type}
    {wft.object_type = c.workflow_key}
}

if { ![empty_string_p $object_id] } {
    lappend where {o.object_id = :object_id}
}

switch $type {
    unassigned {
	lappend select {tr.transition_name as task_name}
	lappend from {wf_tasks t}
	lappend from {wf_transitions tr}
	lappend where {tr.workflow_key = t.workflow_key}
	lappend where {tr.transition_key = t.transition_key}
	lappend where {not exists (select 1 from wf_task_assignments tas where tas.task_id = t.task_id)}
	lappend where {t.state = 'enabled'}
	lappend where {c.state = 'active'}
    }
    default {
	lappend select {t.transition_name as task_name}
	lappend from {wf_user_tasks t}
	lappend where {t.user_id = :user_id} 
    }   
}

switch $type {
    own {
	lappend from {users u}
	lappend where {t.state = 'started'} {t.holding_user = t.user_id} {u.user_id = t.user_id}
    }
    enabled {
	lappend where {t.state = 'enabled'}
    }
}

set sql "
select [join $select ",\n       "]
from   [join $from ",\n       "]
where  [join $where "\n   and "]"

db_multirow task_list started_tasks_select $sql {
    set task_url "[export_vars -base "task" {task_id return_url}]"
}
