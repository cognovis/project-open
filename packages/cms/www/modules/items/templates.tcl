# /modules/items/templates.tcl
# Display information about templates associated with the item.

request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap

set user_id [User::getID]

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# check if the user has write permission on the types module
set can_set_default_template [db_string allowed_set_p ""]

db_1row get_iteminfo "" -column_array iteminfo

set content_type $iteminfo(object_type)


# templates registered to this item
db_multirow registered_templates get_reg_templates ""

# templates registered to this content type
db_multirow type_templates get_type_templates ""

set return_url "index?item_id=$item_id&mount_point=sitemap"
