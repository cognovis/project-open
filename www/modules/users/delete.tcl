# Delete a subgroup

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value users

# Determine if the group is empty
set is_empty [db_string get_status ""]

# If nonempty, show error
if { [string equal $is_empty "f"] } {

  set message "This group is not empty."
  set return_url "modules/sitemap/index"
  set passthrough [list [list id $id] [list parent_id $parent_id]]
  template::forward "../../error?message=$message&return_url=$return_url&passthrough=$passthrough"

} else {

  # Otherwise, delete the group
  db_transaction {
      db_exec_plsql delete_group "begin acs_group.del(:id); end;"
  }

  # Remove it from the clipboard, if it exists
  set clip [clipboard::parse_cookie]
  clipboard::remove_item $clip $mount_point $id
  clipboard::set_cookie $clip
  clipboard::free $clip 

  template::forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}






