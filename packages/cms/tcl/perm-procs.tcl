##############################################
#
# Functions dealing with permissions
#
##############################################

ad_proc -public content::show_error { 
  message {return_url {}} {passthrough {}}
} {

  Redirect the user to an error message
  In the future, have this procedure produce a custom, internationalized
  error message, or something

  Will pick up mount_point, id, parent_id if they exist in the calling
  frame


} {
  
  if { [template::util::is_nil return_url] } {
    set return_url [ns_conn url]
  }

  foreach var { mount_point id parent_id } {
    upvar $var $var
    if { ![template::util::is_nil $var] } {
      lappend passthrough [list $var [set $var]]
    }
  }

  template::forward "[ad_conn package_url]error?[export_vars { message return_url passthrough}]"
}
  

ad_proc -public content::check_access { object_id privilege args } { 

  Query the datatbase for access, show the error page if
  no sufficient access is found. Set up an array
  called "user_permissions" in the calling frame, where the keys
  are permissions and the values are "t" or "f"
  Flags:
  -user_id <user_id>
  -mount_point <mount_point>
  -parent_id <parent_id>
  -return_url <return_url>
  -passthrough < { {name value} {name value} ... }
  -request_error: if present, use request error as opposed to error box
  -refresh: if present, update query cache
} {

  # Set up the default options
  foreach varname { mount_point return_url parent_id passthrough } {
    set opts($varname) ""
  }

  template::util::get_opts $args 

  if { [template::util::is_nil opts(user_id)] } {
    set user_id [User::getID]
  } else {
    set user_id $opts(user_id)
  }  

  # Query the database, set up the array
  upvar user_permissions user_permissions

  if { [info exists opts(refresh)] } {
    set switches "-refresh"
  } else {
    set switches ""
  }

  set perm_list [db_list_of_lists ca_get_perm_list ""]
    
  template::util::list_of_lists_to_array $perm_list user_permissions

  # If we have no permission to view this page, abort
  if { [string equal $user_permissions($privilege) f] } {
    foreach varname { mount_point return_url parent_id passthrough } {
      set $varname $opts($varname)
    }

    # See if the user is even logged in
      set user_name [db_string ca_get_user_name ""]

    if { [template::util::is_nil user_name] } {
      set msg "You are not logged in. Press Ok to go to the login screen."
      set return_url "[ad_conn package_url]signin"   
    } else {

      # Get the error message
        db_0or1row ca_get_msg_info "" -column_array msg_info

      if { ![info exists msg_info] } {
	set msg "Access Denied: no such privilege $privilege"
      } else {
	set msg "Access Denied: you do not possess the $msg_info(perm_name)"
	append msg " privilege on $msg_info(obj_name)"
      }
    }

    # Show the error message
    lappend passthrough [list mount_point $opts(mount_point)] \
                        [list parent_id $opts(parent_id)]

    # Display either the request error or redirect ot an error box
    if { [info exists opts(request_error)] } {
      template::request::error access_denied $msg
      return
    } else {
      content::show_error $msg $return_url $passthrough
    }

  }  

}

ad_proc -public content::flush_access_cache { {object_id {}} } {

  Flush the cache used by check_access

} {
  template::query::flush_cache "content::check_access ${object_id}*"
}

ad_proc -public content::perm_form_generate { form_name_in {passthrough "" } } {

  Generate a form for modifying permissions
  Requires object_id, grantee_id, user_id to be set in calling frame

} {

  upvar perm_form_name form_name
  set form_name $form_name_in

  upvar __sql sql
  set sql [db_map pfg_get_permission_boxes]
  
  uplevel {
    set is_request [form is_request $perm_form_name]
   
    # Get a list of all the possible permissions, along with a flag
    # to see if the user has the permission
    set permission_options [list]
    set permission_values  [list]

    db_multirow permission_boxes pfg_execute_gpb $__sql {
      if { [string equal $parent_permission_p f] } {
        lappend permission_options [list $label $privilege]
        if { [string equal $permission_p t] && $is_request } {
          lappend permission_values $privilege
        }
      }
    }

    # Only show checkboxes if the privilege is in pf_show_boxes
    # The join is just a hack for now
    # set pf_show_boxes [join $pf_show_boxes "|"]

    element create $perm_form_name object_id -label "Object ID" \
      -datatype integer -widget hidden -param

    element create $perm_form_name grantee_id -label "Grantee ID" \
      -datatype integer -widget hidden -param

    element create $perm_form_name pf_boxes -label "Permissions" \
      -datatype text -widget checkbox -options $permission_options \
      -values $permission_values -optional

    element create $perm_form_name pf_is_recursive \
      -label "Apply changes to child items and subfolders ?" \
      -datatype text \
      -widget radio -options { {Yes t} {No f} } -values { f }
  }
  
  foreach varname $passthrough {
    uplevel "element create $form_name $varname -label \"$varname\" \\
               -datatype text -widget hidden -value \$$varname -optional"
  }
  
}


ad_proc -public content::perm_form_process { form_name_in } {

  Process the permission form

} {

  upvar perm_form_name form_name
  set form_name $form_name_in

  upvar __sql_grant sql_grant
  upvar __sql_revoke sql_revoke
  set sql_grant [db_map pfp_grant_permission_1]
  set sql_revoke [db_map pfp_revoke_permission_1]
  
  uplevel {

    if { [form is_valid $perm_form_name] } {

      set user_id [User::getID]

      form get_values $perm_form_name object_id grantee_id pf_is_recursive
      set permission_values [element get_values $perm_form_name pf_boxes]

      db_transaction {

	  # Assign checked permissions, unassign unchecked ones
	  foreach pair $permission_options {
	      set privilege [lindex $pair 1]
	      if { [lsearch $permission_values $privilege] >= 0 } {
                  db_dml pfp_grant_permission $__sql_grant
	      } else {
                  db_dml pfp_revoke_permission $__sql_revoke
	      }
	  }

      }
  
      # Recache the permissions
      content::check_access $object_id "cm_read" \
        -user_id $user_id -refresh

    }
  }

}





