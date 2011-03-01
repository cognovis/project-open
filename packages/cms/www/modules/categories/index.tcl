# Index page for keywords

request create -params {
  id -datatype keyword -optional
  mount_point -datatype keyword -optional -value categories
  parent_id -datatype keyword -optional
}

set original_id $id

set img_checked "[ad_conn package_url]resources/checked.gif"

# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"

set root_id [cm::modules::${mount_point}::getRootFolderID]
if { [util::is_nil id] || [string equal $id _all_] } {
  set where_clause "k.parent_id is null"
} else {
  set where_clause "k.parent_id = :id"
}

# Get self

if { ![util::is_nil id] && ![string equal $id _all_] } {
    db_1row get_info "" -column_array info
} else {
  set info(is_leaf) "f"
  set info(heading) ""
  set info(description) "You can create content categories here
in order to classify content items."
  set info(path) "/"
}

if { [string equal $info(is_leaf) t] } {
  set what "keyword"
} else {
  set what "category"
}

set clip [clipboard::parse_cookie]

# Get children
db_multirow items get_items ""

# Get the parent id if it is missing
if { [util::is_nil parent_id] && ![util::is_nil id] } {
    set parent_id [db_string get_parent_id ""]
}






