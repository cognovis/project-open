# /workspace/index.tcl

request create
request set_param id -datatype keyword -optional
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value workspace

set user_id [User::getID]


# first part of the where clause gets all assignments for the individual
# and for any groups to which the individual belongs.

db_multirow items get_workspace_items ""


# don't cache this page
#ns_set put [ns_conn outputheaders] Pragma "No-cache"





