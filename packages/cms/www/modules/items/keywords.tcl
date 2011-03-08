# Display a list of keywords for the item

# page variables
template::request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value "sitemap"
}

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error


set name [db_string get_name ""]

db_multirow keywords get_keywords ""

set page_title "Content Keywords for $name"
