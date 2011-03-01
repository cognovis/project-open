namespace eval User {

  # redirect if the user is not registered.
  
  proc checkRegistration { url } {
    
    if { [getID] == 0 } { 
      ad_returnredirect $url
    }
  }

  # set the ad_user_login cookie 

  proc login { user_id } {

    ad_user_login -forever $user_id

  }

  # get the current user ID.  Return 0 if no user is signed in.

  proc getID {} {

    set user_id [ad_get_user_id]

  }

  # get the name of the current user.

  ad_proc getName { { which "full" } } {

    switch $which {

      full  { set col "first_names || ' ' || last_name" }
      first { sel col "first_names" }
      last  { set col "last_name" }
    }

    set user_id [ad_util_get_cookie acs_user]

    return [db_string gn_get_name "select 
        $col
      from 
        persons
      where
        person_id = [getID]"]
  }




  # a cms admin exists if a user has the 'cm_admin' privilege
  #   on the CMS pages root folder
  ad_proc cms_admin_exists {} {
  
      set admin_exists [db_string cae_admin_exists ""]

      if { [string equal $admin_exists t] } {
          return 1
      } else {
          return 0
      }
  }

}

