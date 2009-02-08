#
# Expects: 
#  user_id:optional
#  return_url:optional
#  edit_p:optional
#  message:optional
#  show_groups_p:optional

auth::require_login -account_status closed

if { ![exists_and_not_null user_id] } {
    set user_id [ad_conn untrusted_user_id]
} elseif { $user_id != [auth::get_user_id -account_status closed] } {
    permission::require_permission -object_id $user_id -privilege admin
}

if { ![exists_and_not_null return_url] } {
    set return_url [ad_conn url]
}

if { ![exists_and_not_null show_groups_p] } {
    set show_groups_p 0
}

set action_url "[subsite::get_element -element url]user/basic-info-update"

acs_user::get -user_id $user_id -array user -include_bio

set authority_name [auth::authority::get_element -authority_id $user(authority_id) -element pretty_name]

set form_elms { authority_id username first_names last_name email screen_name url bio }
foreach elm $form_elms {
    set elm_mode($elm) {}
}
set read_only_elements [auth::sync::get_sync_elements -authority_id $user(authority_id)]
set read_only_notice_p [expr {[llength $read_only_elements] > 0}]
if { ![acs_user::site_wide_admin_p] } {
    lappend read_only_elements authority_id username
}
foreach elm $read_only_elements {
    set elm_mode($elm) {display}
}
set first_element {}
foreach elm $form_elms {
    if { $elm_mode($elm) eq "" && ($elm ne "username" && [auth::UseEmailForLoginP]) } {
        set first_element $elm
        break
    }
}
set focus "user_info.$first_element"
set edit_mode_p [expr ![empty_string_p [form::get_action user_info]]]

set form_mode display
if { [exists_and_equal edit_p 1] } {
    set form_mode edit
}

ad_form -name user_info -cancel_url $return_url -action $action_url -mode $form_mode -form {
    {user_id:integer(hidden),optional}
    {return_url:text(hidden),optional}
    {message:text(hidden),optional}
}

if { [llength [auth::authority::get_authority_options]] > 1 } {
    ad_form -extend -name user_info -form {
        {authority_id:text(select)
            {mode $elm_mode(authority_id)}
            {label "[_ acs-subsite.Authority]"}
            {options {[auth::authority::get_authority_options]}}
        }
    }
}
if { $user(authority_id) != [auth::authority::local] || ![auth::UseEmailForLoginP] || \
     ([acs_user::site_wide_admin_p] && [llength [auth::authority::get_authority_options]] > 1) } {
    ad_form -extend -name user_info -form {
        {username:text(text)
            {label "[_ acs-subsite.Username]"}
            {mode $elm_mode(username)}
        }
    }
}

# TODO: Use get_registration_form_elements, or auto-generate the form somehow? Deferred.


ad_form -extend -name user_info -form {
    {first_names:text
        {label "[_ acs-subsite.First_names]"}
        {html {size 50}}
        {mode $elm_mode(first_names)}
    }
    {last_name:text
        {label "[_ acs-subsite.Last_name]"}
        {html {size 50}}
        {mode $elm_mode(last_name)}
    }
    {email:text
        {label "[_ acs-subsite.Email]"}
        {html {size 50}}
        {mode $elm_mode(email)}
    }
}

if { [acs_user::ScreenName] ne "none" } {
    ad_form -extend -name user_info -form \
        [list \
             [list screen_name:text[ad_decode [acs_user::ScreenName] "solicit" ",optional" ""] \
                  {label "[_ acs-subsite.Screen_name]"} \
                  {html {size 50}} \
                  {mode $elm_mode(screen_name)} \
                 ]]
}

ad_form -extend -name user_info -form {
    {url:text,optional
        {label "[_ acs-subsite.Home_page]"}
        {html {size 50}}
        {mode $elm_mode(url)}
    }
}

set groups_belonging_to [db_list get_party_groups { select group_id from group_distinct_member_map where member_id = :user_id }]

set package_id [contact::package_id -party_id $user_id]
set package_id [lindex [lsort [apm_package_ids_from_key -package_key contacts -mounted]] 0]
set default_group_id [contacts::default_group -package_id $package_id]

set ams_forms [list "${package_id}__$default_group_id"]
foreach group [contact::groups -expand "all" -package_id $package_id -party_id $user_id] {
    set group_id [lindex $group 1]
    if { [lsearch $groups_belonging_to $group_id] >= 0 } {
        lappend ams_forms "${package_id}__${group_id}"
    }
}
set form_elements [list]
foreach form_element [ams::ad_form::elements -package_key "contacts" -object_type "person" -list_names $ams_forms] {
    if { ![regexp {^(first_names|last_name|email):} $form_element match] } {
	lappend form_elements $form_element
    }
}


if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
    set privacy_setting_options [list]
    if { $object_type eq "organization" } {
	lappend privacy_setting_options [list [_ intranet-contacts.This_organization_has_closed_down] gone_p]
    } else {
	lappend privacy_setting_options [list [_ intranet-contacts.This_person_is_deceased] gone_p]
    }
    lappend privacy_setting_options [list [_ intranet-contacts.Do_not_email] email_p]
    lappend privacy_setting_options [list [_ intranet-contacts.Do_not_mail] mail_p]
    lappend privacy_setting_options [list [_ intranet-contacts.Do_not_phone] phone_p]

    lappend form_elements [list contact_privacy_settings:boolean(checkbox),multiple,optional \
			       [list label [_ intranet-contacts.Privacy_Settings]] \
			       [list options $privacy_setting_options] \
			      ]
}

ad_form -extend -name user_info -form $form_elements


callback contact::contact_form -package_id $package_id -form user_info -object_type "person" -party_id $user_id


ad_form -extend -name user_info -form {
    {bio:text(textarea),optional
        {label "[_ acs-subsite.About_You]"}
        {html {rows 8 cols 60}}
        {mode $elm_mode(bio)}
        {display_value {[ad_text_to_html -- $user(bio)]}}
    }
} -on_request {
    set revision_id [contact::live_revision -party_id $user_id]
    foreach form $ams_forms {
	ams::ad_form::values -package_key "contacts" \
	    -object_type "person" \
	    -list_name $form \
	    -form_name "user_info" \
	    -object_id $revision_id
    }
    callback contact::special_attributes::ad_form_values -party_id $user_id -form "party_ae"
    foreach var { authority_id first_names last_name email username screen_name url bio } {
        set $var $user($var)
    }

} -on_submit {

    # Makes the email an image or text according to the level of privacy
    catch {email_image::edit_email_image -user_id $user_id -new_email $email} errmsg

    set user_info(authority_id) $user(authority_id)
    set user_info(username) $user(username)
    foreach elm $form_elms {
        if { $elm_mode($elm) eq "" && [info exists $elm] } {
            set user_info($elm) [string trim [set $elm]]
        }
    }

    array set result [auth::update_local_account \
                          -authority_id $user(authority_id) \
                          -username $user(username) \
                          -array user_info]


    # Handle authentication problems
    switch $result(update_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $result(element_messages)] == 0 } {
                form set_error user_info $first_element $result(update_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $result(element_messages) {
                form set_error user_info $elm_name $elm_error
            }
            break
        }
    }
 
    callback contact::special_attributes::ad_form_save -party_id $user_id -form "user_info"

    set previous_revision_id [contact::live_revision -party_id $user_id]
    set revision_id [contact::revision::new -party_id $user_id]
    
    # we copy all the attributes from the old id to the new one
    # a user may not have permission to view all attributes
    # for a contact, and this way the values of the attributes
    # they do not have permission to edit are preserved the follwing
    # foreach saves the values they have edited
    ams::object_copy -from $previous_revision_id -to $revision_id
    
    
    foreach form $ams_forms {
	ams::ad_form::save -package_key "contacts" \
	    -object_type "person" \
	    -list_name $form \
	    -form_name "user_info" \
	    -object_id $revision_id
        }
    
    # We need to flush the cache for every attribute_id that this party has
    set flush_attribute_list [db_list_of_lists get_attribute_ids {
	select
	distinct
	ams_a.attribute_id
	from
	ams_attribute_values ams_a,
	ams_attribute_values ams_b,
	acs_objects o
	where
	ams_a.object_id = ams_b.object_id
	and ams_b.object_id = o.object_id
	and o.context_id = :user_id
    }]
    
    foreach attr_id $flush_attribute_list {
	util_memoize_flush [list ams::values_not_cached \
				-package_key "contacts" \
				-object_type "person" \
				-object_id $attr_id]
    }

    if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
	set contact_privacy_settings [template::element::get_values user_info contact_privacy_settings]
	set gone_p 0
	set email_p 1
	set mail_p 1
	set phone_p 1
	if { [lsearch $contact_privacy_settings gone_p] >= 0 } {
	    set gone_p 1
	    set email_p 0
	    set mail_p 0
	    set phone_p 0
	} else {
	    if { [lsearch $contact_privacy_settings email_p] >= 0 } {
		set email_p 0
	    }
	    if { [lsearch $contact_privacy_settings mail_p] >= 0 } {
		set mail_p 0
	    }
	    if { [lsearch $contact_privacy_settings phone_p] >= 0 } {
		set phone_p 0
	    }
	}
	contact::privacy_set \
	    -party_id $user_id \
	    -email_p $email_p \
	    -mail_p $mail_p \
	    -phone_p $phone_p \
	    -gone_p $gone_p
    }
    contact::flush -party_id $user_id
    contact::search::flush_results_counts
    
    callback contact::contact_form_after_submit -party_id $user_id -package_id $package_id -object_type "person" -form "user_info"

} -after_submit {
    if {[ad_conn account_status] eq "closed"} {
        auth::verify_account_status
    }
    
    ad_returnredirect $return_url
    ad_script_abort
}

# LARS HACK: Make the URL and email elements real links
if { ![form is_valid user_info] } {
    element set_properties user_info email -display_value "<a href=\"mailto:[element get_value user_info email]\">[element get_value user_info email]</a>"
    if {![string match -nocase "http://*" [element get_value user_info url]]} {
	element set_properties user_info url -display_value \
		"<a href=\"http://[element get_value user_info url]\">[element get_value user_info url]</a>"
    } else {
	element set_properties user_info url -display_value \
		"<a href=\"[element get_value user_info url]\">[element get_value user_info url]</a>"
    }
}
