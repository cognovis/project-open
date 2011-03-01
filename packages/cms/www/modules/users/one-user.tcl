request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param parent_id -datatype keyword -optional

set passthrough "mount_point=$mount_point&parent_id=$parent_id"

# Find basic user params
db_1row get_info "" -column_array info

# Find the groups to which this user belongs
db_multirow groups get_groups ""
