# Delete a content item and all of its revisions, 

request create
request set_param item_id -datatype keyword
request set_param mount_point -datatype keyword -value sitemap

db_transaction {
    # permissions check - must have cm_write permissions on item to delete
    content::check_access $item_id cm_write -user_id [User::getID]

    # get all the parent_id's of the items being deleted
    #   because we need to flush the paginator cache for each of these folders
    set flush_list [db_list flush ""]

    db_exec_plsql item_delete "
  begin 
    content_item.del(
      item_id => :item_id
    ); 
  end;" 
}

# flush cache
set root_id [cm::modules::${mount_point}::getRootFolderID]
set flushed_list [list]
foreach parent_id $flush_list {
  if { [lsearch -exact $flushed_list $parent_id] == -1 } {
    if { $parent_id == $root_id } {
      set parent_id ""
    }
    cms_folder::flush $mount_point $parent_id
    lappend flushed_list $parent_id
  }
}

template::forward "../sitemap/index?id="
