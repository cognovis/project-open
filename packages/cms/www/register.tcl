# cms/www/register.tcl 

form create register_user -elements {
  user_id -datatype integer -widget hidden
  first_name -datatype text -widget text -html { size 30 } -label "First Name"
  last_name -datatype text -widget text -html { size 30 } -label "Last Name"
  email -datatype text -widget text -html { size 30 } -validate { \
    { template::util::is_unique parties email $value } \
    { The email <b>$value</b> is taken. } \
  } -label "E-Mail"
  screen_name -datatype text -widget text -html { size 20 } -validate { \
    { template::util::is_unique users screen_name $value } \
    { The screen name <b>$value</b> is taken.  Please try another one. } \
  } -label "Screen Name"
  password -datatype text -widget password -html { size 20 } -validate { \
    { string equal $value [ns_queryget password.confirm] } \
    { Passwords do not match. } \
  } -label "Password"
  password.confirm -datatype text -widget password -html { size 20 } \
    -label "Confirm Password"
}


if { [form is_request register_user] } {

    set user_id [db_nextval "acs_object_id_seq"]

    set cms_admin_exists [User::cms_admin_exists]

    if { $cms_admin_exists == 0 } {
	set is_admin t
    } else {
	set is_admin f
    }

    element set_properties register_user user_id -value $user_id
}


if { [form is_valid register_user] } {

    form get_values register_user user_id email first_name last_name \
	    password screen_name

    db_transaction {
        array set results [auth::create_user -user_id $user_id -password $password \
			       -email $email -screen_name $screen_name \
			       -first_names $first_name -last_name $last_name ]

        # if there are no users with the 'cm_admin' privilege 
        #   (the CMS has never been used), then this user will be the admin
        set cms_admin_exists [User::cms_admin_exists]
        if { $cms_admin_exists == 0 } {
            set is_admin t
        } else {
            set is_admin f
        }

        # make admin - grant 'cm_admin' privileges for all content items
        #   and for content modules
        if { [string equal $is_admin t] } {
            db_exec_plsql grant_permissions {*SQL*}
        }

        User::login $user_id
    }

    template::forward index
}
