# Delete a subject category

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value categories

# Determine if the folder is empty
set is_empty [db_string get_empty_status ""]

# If nonempty, show error
if { [string equal $is_empty "f"] } {

  set message "This category contains subcategories and cannot be deleted."
  set return_url "modules/categories/index"
  set passthrough [list [list id $id] [list parent_id $parent_id]]
  template::forward "../../error?message=$message&return_url=$return_url&passthrough=$passthrough"

} else {

  db_transaction {
      # Otherwise, delete the folder
      set delete_keyword [db_exec_plsql delete_keyword "begin :1 := content_keyword.del(:id); end;"]
  }

  # Remove it from the clipboard, if it exists
  set clip [clipboard::parse_cookie]
  clipboard::remove_item $clip $mount_point $id
  clipboard::set_cookie $clip
  clipboard::free $clip 

  template::forward "refresh-tree?id=_all_&goto_id=$parent_id&mount_point=$mount_point"
}
 
