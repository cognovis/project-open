# Assign marked keywords to an item

# page variables
template::request create
template::request set_param item_id -datatype integer
template::request set_param mount_point -datatype keyword \
  -optional -value "sitemap"

if { [template::util::is_nil item_id] } {
  set resolved_id [cm::modules::${mount_point}::getRootFolderID]
} else {
  set resolved_id $item_id
}

# Preserve the item_id since the clipboard::parse_cookie wil overwrite it
set saved_item_id $item_id
set clip [clipboard::parse_cookie]
db_transaction {
    clipboard::map_code $clip categories {
        if { [catch { 
            db_exec_plsql assign_keyword {

       begin content_keyword.item_assign(:resolved_id, :item_id); end;

            }
        } errmsg] } {
        }    
    }
}

clipboard::free $clip

template::forward "../items/index?item_id=$saved_item_id&mount_point=$mount_point"
