# workflow.tcl


request create
request set_param transition -datatype keyword -value "all"


if { [string equal $transition "all"] } {
    set transition_name "All Tasks"
    set transition_sql ""
} else {

    set transition_name [db_string get_name "" -default ""]

    if { [string equal $transition_name ""] } {
	ns_log notice "workflow.tcl - Bad transition - $transition"
	forward "workflow"
    }
    set transition_sql "and ca.role_key = trans.role_key"
}



set date_format "'Mon. DD, YYYY HH24:MI:SS'"


db_multirow active_tasks get_active ""

db_multirow awaiting_tasks get_waiting ""

set page_title "Workflow Tasks - $transition_name"
