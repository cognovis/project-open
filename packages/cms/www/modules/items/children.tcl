# Display information about items for which the item is the context.

# page variables
request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# create a form to add child items

set child_types [db_list_of_lists get_child_types ""]

# do not display template if this content type does not allow children
if { [llength $child_types] == 0 } { adp_abort }

if { [string equal $user_permissions(cm_new) t] } {
  form create add_child -method get -action "create-1"
  element create add_child parent_id -datatype integer \
    -widget hidden -value $item_id
  element create add_child content_type -datatype keyword \
    -options $child_types -widget select 
}

db_multirow children get_children ""
