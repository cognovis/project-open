# Delete a folder (only if does not contain any items).
# Delete any symlinks pointing to this folder (possibly give a warning).

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value sitemap



# permission check - user must have cm_write on this folder to delete it
content::check_access $id cm_write -user_id [User::getID]

# Determine if the folder is empty
set is_empty [db_string check_empty ""]

# If nonempty, show error
if { [string equal $is_empty "f"] } {

  set message "This folder is not empty."
  set return_url "modules/sitemap/index"
  set passthrough [list [list id $id] [list parent_id $parent_id]]
  template::forward "../../error?message=$message&return_url=$return_url&passthrough=$passthrough"

} else {

  # Otherwise, delete the folder
  db_transaction {
      db_exec_plsql delete_folder "begin content_folder.del(:id); end;"
  }

  # Remove it from the clipboard, if it exists
  set clip [clipboard::parse_cookie]
  clipboard::remove_item $clip $mount_point $id
  clipboard::set_cookie $clip
  clipboard::free $clip 

  # Flush paginator cache
  cms_folder::flush $mount_point $parent_id

  template::forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}
