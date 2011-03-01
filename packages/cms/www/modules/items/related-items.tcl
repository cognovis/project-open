request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -value "sitemap"

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

db_multirow related get_related ""

