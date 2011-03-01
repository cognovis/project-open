request create
request set_param object_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param parent_id -datatype keyword -optional
request set_param return_url -datatype text -optional
request set_param passthrough -datatype text -optional

#set passthrough "id=$object_id&mount_point=$mount_point&parent_id=$parent_id"

set user_id [User::getID]


# Determine if the user can modify permissions on this object
# Should it dump a user to an error page if no access ?
#content::check_access $id "cm_perm" -db $db -user_id $user_id \
#  -parent_id $parent_id -mount_point $mount_point

# Determine if the user is the site wide admin, and if he has the rights to \
# modify permissions at all
content::check_access $object_id "cm_examine" \
  -user_id $user_id -mount_point $mount_point -parent_id $parent_id

if { ![string equal $user_permissions(cm_perm) t] } {
  return
}

# Get a list of permissions that users have on the item
db_multirow permissions get_permissions ""


# Create a URL passthrough stub to access permissions
set perms_url_extra "return_url=$return_url&passthrough=$passthrough&object_id=$object_id"


set header "\[ <a href=\"../permissions/permission-grant?$perms_url_extra\">Grant</a> \] more permissions to a marked user"
