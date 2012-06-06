ad_page_contract {
    Page to register a translation from a remote server.
    Creates the user if not already available
} {
    locale
    package_key 
    message_key
    sender_email
    { package_version "" }
    { sender_first_names "System" }
    { sender_last_name "Administrator" }
    { message:allhtml "" }
    { comment:allhtml "" }
}

# No security. 
# That's right. Everybody should be able to create such messages.

ns_log Notice "lang_message_register: locale=$locale, package_key=$package_key, message_key=$message_key, package_version=$package_version, sender_email=$sender_email, message=$message, comment=$comment"

set old_message $message
set deleted_p "f"
set conflict_p "f"
set upgrade_status "no_upgrade"
set system_url ""

# -----------------------------------------------------------------
# Lookup user_id or create entry
# -----------------------------------------------------------------
# Keep in mind that the email and other data might be completely fake.

ns_log Notice "Check if the user already has an account: $sender_email"
set overwrite_user [db_string user_id "select party_id from parties where lower(email) = lower(:sender_email)" -default 0]

if {0 != $overwrite_user} {
    # The user already exists:
    # Make sure there are no more then $max_incidents today from the same IP
    
    # ToDo: Implement !!!

} else {

    # Doesn't exist yet - let's create it
    ns_log Notice "new-system-incident: creating new user '$sender_email'"
    array set creation_info [auth::create_user \
	-email $sender_email \
	-url $system_url \
	-verify_password_confirm \
	-first_names $sender_first_names \
	-last_name $sender_last_name \
	-screen_name "$sender_first_names $sender_last_name" \
	-username "$sender_first_names $sender_last_name" \
	-password $sender_first_names \
	-password_confirm $sender_first_names \
    ]

    ns_log Notice "new-system-incident: creation info: [array get creation_info]"
    ns_log Notice "new-system-incident: checking for '$sender_email' after creation"
    set overwrite_user [db_string user_id "select party_id from parties where lower(email) = lower(:sender_email)" -default 0]

}



db_dml insert "
	insert into lang_messages_audit (
		audit_id, package_key, message_key, 
		locale, old_message, comment_text, 
		overwrite_user, overwrite_date,
		deleted_p, sync_time, 
		conflict_p, upgrade_status
	) values (
		nextval('lang_messages_audit_id_seq'::text), :package_key, :message_key, 
		:locale, :old_message, :comment, 
		:overwrite_user, now(),
		:deleted_p, now(),
		:conflict_p, :upgrade_status
	)
"

doc_return 200 "text/html" "OK"
