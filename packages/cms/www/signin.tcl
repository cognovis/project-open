form create sign_in_user 

element create sign_in_user screen_name \
	-datatype text \
	-widget text \
	-html { size 20 } \
	-label "Screen Name"

element create sign_in_user password \
	-datatype text \
	-widget password \
	-html { size 20 } \
	-label "Password"



if { [form is_valid sign_in_user] } {

  form get_values sign_in_user screen_name password

  db_transaction {

      db_0or1row get_info "" -column_array info

      set is_valid_login 0

      if { [array exists info] } {

          set hashed_password [ns_sha1 "$password$info(salt)"]
          set is_valid_login [string equal $info(password) $hashed_password]
      }

      if { ! $is_valid_login } {

          element set_error sign_in_user screen_name \
              "The screen name and password combination is invalid."

      } else {

          User::login $info(user_id)
          template::forward index
          return
      }
  }
}

