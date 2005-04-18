# Assign marked keywords to item

request create -params {
  id -datatype keyword
  mount_point -datatype keyword -optional -value sitemap
  parent_id -datatype keyword -optional
}

set user_id [User::getID]
set ip [ns_conn peeraddr]
set folder_list [list]

# Check permissions
content::check_access $id cm_write \
  -mount_point $mount_point -parent_id $parent_id \
  -return_url "modules/sitemap/index" \
  -passthrough [list id $parent_id] 

if { [template::util::is_nil id] } {
  set root_id [cm::modules::${mount_point}::getRootFolderID]
} else {
  set root_id $id
}

set clip [clipboard::parse_cookie]

db_transaction {
    clipboard::map_code $clip categories {
        if { [catch { 
            db_exec_plsql item_assign "
        begin 
         :1 := content_keyword.item_assign(
          :root_id, :item_id, null, :user_id, :ip); 
        end;"
            lappend folder_list [list $mount_point $item_id]

        } errmsg] } {
        }    
    }

}

clipboard::free $clip

# Specify a null id so that the entire branch will be refreshed
template::forward "index?item_id=$id&mount_point=$mount_point"


 
  
  
  
