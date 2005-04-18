# download.tcl
#
# see if this person is authorized to read the file in question
# and if so, write it to the connection.

template::request create
template::request set_param revision_id -datatype integer

set user_id [User::getID]

db_1row get_iteminfo ""

# item_id, is_live

# check cm permissions on file
if { ![string equal $is_live t] } {
  content::check_access $item_id cm_read -user_id $user_id
}

cr_write_content -revision_id $revision_id
