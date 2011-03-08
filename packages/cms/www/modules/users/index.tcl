# This page should allow browsing of group components, with creation of
# new components.

# links:
# users-add.tcl (Add Users to this Group)

request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -value users
request set_param parent_id -datatype keyword -optional

# Determine if the user has admin privileges on the user module
set user_id [User::getID]
set module_id [cm::modules::get_module_id $mount_point]
set admin_p [db_string check_admin ""]

if { [string equal $admin_p t] } {
  set admin_url "make-admin?mount_point=$mount_point&parent_id=$parent_id&target_user_id="
}

set perm_p [db_string check_perm ""]

# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"
set root_id [cm::modules::${mount_point}::getRootFolderID]


if { ![util::is_nil id] } {

  set current_id $id

  # Get info about the current group
  
  db_1row get_info1 "" -column_array info

  set groups_query [db_map get_groups_1] 
  set users_query [db_map get_users_1] 

  set users_eval  {
      set state_html ""
      set the_pipe ""
      foreach pair { {Approved approved} {Rejected rejected} {Banned banned}} {

	set label [lindex $pair 0]
	set value [lindex $pair 1] 

	append state_html $the_pipe

	if { [string equal $member_state $value] } {
	  append state_html "<b>$value</b>"
	} else {
            append state_html "<a href=\"change-user-state?rel_id=${rel_id}&group_id=$id"
	  append state_html "&new_state=$value&mount_point=$mount_point&parent_id=$id\">"
	  append state_html "$value</a>"
	}

	set the_pipe "&nbsp;|&nbsp;"
      }

    }

} else {

  set current_id $module_id

  # the everyone party
  db_1row get_info2 "" -column_array info

  #clipboard::get_bookmark_icon $clip $mount_point $info(group_id) info

  set groups_query [db_map get_groups_2] 
  set users_query [db_map get_users_2] 

  set users_eval {} 
}

# Select subgroups, users
db_multirow subgroups get_subgroups $groups_query
ns_log Notice "users_eval = $users_eval"
db_multirow -extend state_html users get_users $users_query $users_eval

set return_url [ns_conn url]
