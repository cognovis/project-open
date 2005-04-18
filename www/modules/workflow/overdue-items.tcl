request create
request set_param transition -datatype keyword -value "all"


if { ![string equal $transition "all"] } {
    set transition_name [db_string get_transition_name ""]

    set transition_sql "and trans.transition_key = :transition"

} else {
    set transition_name "All Tasks"
    set transition_sql ""
}


set date_format "'Mon. DD, YYYY HH24:MI:SS'"

db_multirow overdue_tasks get_overdue_tasks ""

set page_title "Outstanding Workflow Tasks - $transition_name"
