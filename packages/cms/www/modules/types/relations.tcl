# relations.tcl
# display registered relation types
# @author Michael Pih

request create
request set_param type -datatype integer -value content_revision

set module_id [db_string get_module_id ""]

# permission check - must have cm_examine on types module
content::check_access $module_id cm_examine -user_id [User::getID] 

db_multirow rel_types get_rel_types ""

db_multirow child_types get_child_types ""
