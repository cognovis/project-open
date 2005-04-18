# workflow/user-tasks.tcl

request create
request set_param party_id -datatype integer


set date_format "'Mon. DD, YYYY HH24:MI:SS'"

set party_name [db_string get_party_name ""]

set date_format "'Mon., DD, YYYY HH24:MI:SS'"

db_multirow active_tasks get_active ""

db_multirow awaiting_tasks get_waiting ""

set page_title "Workflow Tasks Assigned to $party_name"
