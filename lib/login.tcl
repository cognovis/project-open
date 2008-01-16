# Present a login box
#
# Expects:
#   subsite_id - optional, defaults to nearest subsite
#   return_url - optional, defaults to Your Account
# Optional:
#   authority_id
#   username
#   email
#
#   otp_user_id - optional, from previous login
#   otp_enabled_p - optional, OTP = one-time-password
#   otp - optional, the OTP

# -------------------------------------------------------
# Defaults & Variables
# -------------------------------------------------------

if {![exists_and_not_null otp_nr]} { set otp_nr 0}
if {![exists_and_not_null otp_enabled_p]} { set otp_enabled_p ""}
if {![exists_and_not_null time]} { set time ""}
if {![info exists username]} { set username "" }
if {![info exists email]} { set email "" }

set no_otp_message [lang::message::lookup "" intranet-otp.No_OTP_defined_yet "
You need a One Time Password (OTP) for login from your current location.<br>
However, there is no OTP set up for you yet.<br>
Please logon via VPN or Intranet and setup an OTP.
"]

# -------------------------------------------------------
# Parameters and Configuration
# -------------------------------------------------------

set redirect_public_to_ssl_p [parameter::get_from_package_key \
	-package_key intranet-otp \
	-parameter RedirectPublicConnectionToSSLP \
	-default 1
]

# Check if there is an OTP (one time password) module installed
set otp_installed_p [db_string otp_installed "
	select count(*) 
	from apm_enabled_package_versions 
	where package_key = 'intranet-otp'
" -default 0]

# Check if there is an LDAP support module installed
set ldap_installed_p [db_string ldap_installed "
	select count(*) 
	from apm_enabled_package_versions 
	where package_key = 'intranet-ldap'
" -default 0]

set self_registration [parameter::get_from_package_key \
                                  -package_key acs-authentication \
			          -parameter AllowSelfRegister \
			          -default 1]   

if { ![exists_and_not_null package_id] } {
    set subsite_id [subsite::get_element -element object_id]
}

set email_forgotten_password_p [parameter::get \
                                    -parameter EmailForgottenPasswordP \
                                    -package_id $subsite_id \
                                    -default 1]


# -------------------------------------------------------
# Need to login via SSL?
# -------------------------------------------------------

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

# -------------------------------------------------------
# Remember the dude?
# -------------------------------------------------------

# email and username are empty, but we still remember the dude.
if { [empty_string_p $email] && [empty_string_p $username] && [ad_conn untrusted_user_id] != 0 } {
    acs_user::get -user_id [ad_conn untrusted_user_id] -array untrusted_user
    if { [auth::UseEmailForLoginP] } {
        set email $untrusted_user(email)
    } else {
        set authority_id $untrusted_user(authority_id)
        set username $untrusted_user(username)
    }
}

# Persistent login
# The logic is: 
#  1. Allowed if allowed both site-wide (on acs-kernel) and on the subsite
#  2. Default setting is in acs-kernel

set allow_persistent_login_p [parameter::get -parameter AllowPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
if { $allow_persistent_login_p } {
    set allow_persistent_login_p [parameter::get -package_id $subsite_id -parameter AllowPersistentLoginP -default 1]
}
if { $allow_persistent_login_p } {
    set default_persistent_login_p [parameter::get -parameter DefaultPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
} else {
    set default_persistent_login_p 0
}


set subsite_url [subsite::get_element -element url]
set system_name [ad_system_name]

if { ![exists_and_not_null return_url] } {
    set return_url [ad_pvt_home]
}

set authority_options [auth::authority::get_authority_options]

if { ![exists_and_not_null authority_id] } {
    set authority_id [lindex [lindex $authority_options 0] 1]
}

set forgotten_pwd_url [auth::password::get_forgotten_url -authority_id $authority_id -username $username -email $email]

set register_url [export_vars -base "[subsite::get_element -element url]register/user-new" { return_url }]
if { [string equal $authority_id [auth::get_register_authority]] || [auth::UseEmailForLoginP] } {
    set register_url [export_vars -no_empty -base $register_url { username email }]
}

set login_button [list [list [_ acs-subsite.Log_In] ok]]
ad_form -name login -html { style "margin: 0px;" } -show_required_p 0 -edit_buttons $login_button -action "/register/" -form {
    {return_url:text(hidden)}
    {time:text(hidden)}
    {token_id:text(hidden)}
    {hash:text(hidden)}
    {password_hash:text(hidden),optional}
    {otp_enabled_p:text(hidden),optional}
    {otp_user_id:text(hidden),optional}
} 

set username_widget text
if { [parameter::get -parameter UsePasswordWidgetForUsername -package_id [ad_acs_kernel_id]] } {
    set username_widget password
}

set focus {}
if { [auth::UseEmailForLoginP] } {

    if {1 != $otp_enabled_p} {
	ad_form -extend -name login -form [list [list email:text($username_widget),nospell [list label [_ acs-subsite.Email]]]]
    }

    set user_id_widget_name email
    if { ![empty_string_p $email] } {
        set focus "password"
    } else {
        set focus "email"
    }
} else {
    if { [llength $authority_options] > 1 } {
        ad_form -extend -name login -form {
            {authority_id:integer(select) 
                {label "[_ acs-subsite.Authority]"} 
                {options $authority_options}
            }
        }
    }

    ad_form -extend -name login -form [list [list username:text($username_widget),nospell [list label [_ acs-subsite.Username]]]]
    set user_id_widget_name username
    if { ![empty_string_p $username] } {
        set focus "password"
    } else {
        set focus "username"
    }
}
set focus "login.$focus"

if {1 != $otp_enabled_p} {
    ad_form -extend -name login -form {
	{password:text(password),optional
	    {label "[_ acs-subsite.Password]"}
	}
    }
}

# One-Time-Password Enabled - show form element
if {$otp_installed_p && [exists_and_not_null otp_enabled_p]} {

    # Just unconditionally show the OTP.
    # There is now sense to "abuse" this if OTP
    # isn't activated...

    set correct_otp [im_otp_otp -user_id $otp_user_id -otp_nr $otp_nr]
    if {"" == $correct_otp} {
	ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $no_otp_message } }]
	ad_script_abort
    }

    set min_otps_left [parameter::get_from_package_key \
	-package_key intranet-otp \
	-parameter MinOtpsLeftBeforeNotice \
	-default 10
    ]

    set otps_left [llength [im_otp_unused_otps -user_id $otp_user_id]]
    set help_text ""
    if {$otps_left < $min_otps_left} {
	set help_text [lang::message::lookup "" intranet-otp.Few_OTPs_Left "There are only %otps_left% OTPs left. Please update your OTP list<br>or you will loose access from this location."]
    }

    set label [lang::message::lookup "" intranet-otp.OTP "OTP \#$otp_nr"]
    ad_form -extend -name login -form [list [list otp:text(text) [list help_text $help_text] [list label $label] ]]
    ad_form -extend -name login -form [list [list otp_nr:text(hidden)]]
}

set options_list [list [list [_ acs-subsite.Remember_my_login] "t"]]
if { $allow_persistent_login_p } {
    ad_form -extend -name login -form {
        {persistent_p:text(checkbox),optional
            {label ""}
            {options $options_list}
        }
    }
}

ad_form -extend -name login -on_request {
    # Populate fields from local vars

    set persistent_p [ad_decode $default_persistent_login_p 1 "t" ""]

    # One common problem with login is that people can hit the back button
    # after a user logs out and relogin by using the cached password in
    # the browser. We generate a unique hashed timestamp so that users
    # cannot use the back button.

    if {"" == $time} { 
	set time [ns_time]
	ns_log Notice "login: setting time=$time"
    }
    set token_id [sec_get_random_cached_token_id]
    set token [sec_get_token $token_id]
    set hash [ns_sha1 "$time$token_id$token"]

} -on_submit {

    # Check timestamp
    set token [sec_get_token $token_id]
    set computed_hash [ns_sha1 "$time$token_id$token"]
    
    set expiration_time [parameter::get -parameter LoginExpirationTime -package_id [ad_acs_kernel_id] -default 600]
    if { $expiration_time < 30 } { 
        # If expiration_time is less than 30 seconds, it's practically impossible to login
        # and you will have completely hosed login on your entire site
        set expiration_time 30
    }

    if { [string compare $hash $computed_hash] != 0 || \
             $time < [ns_time] - $expiration_time } {
        ad_returnredirect -message [_ acs-subsite.Login_has_expired] -- [export_vars -base [ad_conn url] { return_url }]
        ad_script_abort
    }

    if { ![exists_and_not_null authority_id] } {
        # Will be defaulted to local authority
        set authority_id {}
    }

    if { ![exists_and_not_null persistent_p] } {
        set persistent_p "f"
    }

    if {$ldap_installed_p} {
	# auth_info(auth_status) in: {ok, bad_password,not_ldap}
	array set auth_info [im_ldap_check_user \
				 -email $email \
				 -username $username \
				 -password $password
	]
	
	# Handle authentication errors
	switch $auth_info(auth_status) {
	    ok { 
		auth::issue_login \
		    -user_id $auth_info(user_id) \
		    -persistent=[expr $allow_persistent_login_p && [template::util::is_true $persistent_p]] \
		    -account_status $auth_info(account_status)
		set login_done_p 1
	    }
	    bad_password {
		form set_error login password $auth_info(auth_message)
		break
	    }
	    no_local_user {
		form set_error login $user_id_widget_name $auth_info(auth_message)
		break
	    }
	    ldap_error {
		form set_error login $user_id_widget_name $auth_info(auth_message)
		break
	    }
	    not_ldap {
		# Nothing, continue below with normal authentication
	    }
	    default {
		form set_error login $user_id_widget_name $auth_info(auth_message)
		break
	    }
	}
    }


    if {1 != $otp_enabled_p && ![info exists login_done_p]} {
	array set auth_info {}
	set auth_info(auth_status) ""
	set auth_info(auth_message) "undefined login error"
	
	if {[string equal $auth_info(auth_status) ""]} {
	    # Authenticate.
	    # But don't set the auth-cookie yet, we first have to
	    # make sure that the person has the right to autenticate
	    # from the intranet/intranet:
	    array set auth_info [auth::authenticate \
				     -return_url $return_url \
				     -authority_id $authority_id \
				     -email [string trim $email] \
				     -username [string trim $username] \
				     -password $password \
				     -persistent=[expr $allow_persistent_login_p && [template::util::is_true $persistent_p]] \
				     -no_cookie=1 \
	    ]
	}
	
	# Handle authentication errors
	switch $auth_info(auth_status) {
	    ok { }
	    bad_password {
		form set_error login password $auth_info(auth_message)
		break
	    }
	    default {
		form set_error login $user_id_widget_name $auth_info(auth_message)
		break
	    }
	}

	set otp_user_id 0
	if {[exists_and_not_null auth_info(user_id)]} { set otp_user_id $auth_info(user_id) }
    }

    # Check if there is a secure login module installed
    # and redirect if the user requires extra auth.
    if {$otp_installed_p} {

	if {[exists_and_not_null otp]} {

	    # We now have to check a lot of stuff to be sure
	    # the OTP is OK:
	    # - Check whether the OTP is correct (otp_nr)
	    # - Check whether the password_hash is correct
	    #   and not outdated

	    # Check the OTP - just reproduce and compare...
	    set correct_otp [im_otp_otp -user_id $otp_user_id -otp_nr $otp_nr]
	    if {"" == $correct_otp} {
		form set_error login otp $no_otp_message
		break
	    }

	    if {![string equal [string tolower [string trim $otp]] [string tolower [string trim $correct_otp]]]} {
		set remaining_attempts [im_otp_failed_login_attempt -user_id $otp_user_id]
		set bad_otp_message [lang::message::lookup "" intranet-otp.Bad_OTP "Bad One Time Password - Please try again.<br>There are %remaining_attempts% attempts left."]
		form set_error login otp $bad_otp_message
		break
	    }

	    # Check the password_hash. Somebody could try to
	    # skip the password auth and fake it..
	    set correct_password_hash [im_generate_auto_login -expiry_date $time -user_id $otp_user_id]
	    set bad_pwdhash_message [lang::message::lookup "" intranet-otp.Bad_Pwd_Hash "Bad Password Hash - Please try again."]
	    if {![string equal $password_hash $correct_password_hash]} {
		form set_error login otp $bad_pwdhash_message
		break
	    }

#	    ad_return_complaint 1 "<pre>\ntime=$time\notp=$otp\ncorrect_otp=$correct_otp\notp_user_id=$otp_user_id\notp_nr=$otp_nr\ncorrect_password_hash=$correct_password_hash\npassword_hash=$password_hash\n</pre>"

	    # Finally log the dude in!
	    set auth_info(auth_status) "ok"
	    set auth_info(account_status) "ok"
	    set auth_info(user_id) $otp_user_id
	    im_otp_mark_otp_as_used -user_id $otp_user_id -otp_nr $otp_nr
	    im_otp_reset_failed_logins -user_id $otp_user_id
	    # ... continues further below with issuing the cookie

	} else {

	    # OTP is not there yet.
	    # Check if we need to redirect the user
	    if {[im_otp_user_needs_otp $otp_user_id]} {
		
		# Redirect the user to the extended login page
		set password_hash [im_generate_auto_login -expiry_date $time -user_id $otp_user_id]
		set otp_nr [im_otp_next_otp_nr -user_id $otp_user_id]

		ad_returnredirect [export_vars -base [ad_conn url] { \
			email \
			return_url \
			time \
			{otp_enabled_p 1} \
			otp_user_id \
			otp_nr \
			password_hash \
		}]
		ad_script_abort
		
	    } else {
		# Nothing - just continue with the standard auth.
	    }

	}

    }

    # Handle authentication status
    switch $auth_info(auth_status) {
        ok {
	    auth::issue_login \
		-user_id $auth_info(user_id) \
		-persistent=[expr $allow_persistent_login_p && [template::util::is_true $persistent_p]] \
		-account_status $auth_info(account_status)
        }
        bad_password {
            form set_error login password $auth_info(auth_message)
            break
        }
        default {
            form set_error login $user_id_widget_name $auth_info(auth_message)
            break
        }
    }

    if { [exists_and_not_null auth_info(account_url)] } {
        ad_returnredirect $auth_info(account_url)
        ad_script_abort
    }

    # Handle account status
    switch $auth_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $auth_info(account_message) } }]
            ad_script_abort
        }
    }
} -after_submit {

    # We're logged in

    # Handle account_message
    if { [exists_and_not_null auth_info(account_message)] } {
        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $auth_info(account_message) } return_url }]
        ad_script_abort
    } else {
        # No message
        ad_returnredirect $return_url
        ad_script_abort
   }
}
