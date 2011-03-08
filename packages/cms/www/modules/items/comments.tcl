# List comments about an item (or add a new comment)

request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# Check permissions
content::check_access $item_id cm_read \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# The creation_user may be null, in which case 'System' is substituted

db_multirow comments get_comments ""
