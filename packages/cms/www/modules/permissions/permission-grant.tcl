request create
request set_param object_id -datatype integer 
request set_param return_url -datatype text -optional
request set_param passthrough -datatype text -optional
request set_param ext_passthrough -datatype text -optional -value $passthrough

set user_id [User::getID]

# Determine if we have one and only one user on the clipboard
set clip [clipboard::parse_cookie]
set users [clipboard::get_items $clip users]

if { [llength $users] < 1 } {
  content::show_error \
    "There are no users on the clipboard." \
    $return_url $passthrough
    
} elseif { [llength $users] > 1 } {
  content::show_error \
    "There is more than one user on the clipboard. Make sure only
     one user is marked and try again" \
    $return_url $passthrough 
}

set grantee_id [lindex $users 0]

template::forward "../permissions/permission-alter?object_id=$object_id&return_url=$return_url&passthrough=$passthrough&grantee_id=$grantee_id"


