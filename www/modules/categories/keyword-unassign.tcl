# Unassign a keyword from an item

# page variables
template::request create
template::request set_param item_id -datatype integer
template::request set_param keyword_id -datatype integer
template::request set_param mount_point -datatype keyword \
  -optional -value "sitemap"

if { [template::util::is_nil item_id] } {
  set resolved_id [cm::modules::${mount_point}::getRootFolderID]
} else {
  set resolved_id $item_id
}

db_exec_plsql unassign_keyword {
  begin content_keyword.item_unassign(:resolved_id, :keyword_id); end;
}

template::forward "../items/index?item_id=$item_id&mount_point=$mount_point"
