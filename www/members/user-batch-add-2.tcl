ad_page_contract {
    Interface for specifying a list of users to sign up as a batch
    @cvs-id $Id$
} -query {
    userlist:allhtml
    from
    subject
    message:allhtml
    {send_email_p 0}
} -properties {
    title:onevalue
    success_text:onevalue
    exception_text:onevalue
}

subsite::assert_user_may_add_member

# parse the notify_ids arguments 
# ...

set exception_text ""
set success_text ""
set title "Adding new users in bulk"

set group_id [application_group::group_id_from_package_id]

# parse the userlist input a row at a time
# most errors stop the processing of the line but keep going on the
# bigger block
while {[regexp {(.[^\n]+)} $userlist match_fodder row] } {
    # remove each row as it's handled
    set remove_count [string length $row]
    set userlist [string range $userlist [expr $remove_count + 1] end]

    # Distinguish between "Komma" format (email, first, last)
    # and Email list format ("first [middle] last <addr@domain.com>").

    # Try "Komma format" first
    set fields [split $row ,]
    set email [string trim [lindex $fields 0]]
    set first_names [string trim [lindex $fields 1]]
    set last_name [string trim [lindex $fields 2]]

    # Now let's try the other one...
    if {![util_email_valid_p $email]} {
	# We first would have to remove all tabs and normalize
	# multiple spaced in a single space...

	set fields [split $row <]
	set name_field [string trim [lindex $fields 0]]
	set email [string trim [lindex $fields 1]]
	set email_fields [split $email >]
	set email [string trim [lindex $email_fields 0]]
	set email [string tolower $email]
	
	set names [split $name_field {\ }]
	set name_count [llength $names]

	set first_names ""
	set last_name_name ""

	switch $name_count {
	    1 { 
		set first_names [lindex $names 0]
		set last_name [lindex $names 0]		
	    }
	    2 {
		set first_names [lindex $names 0]
		set last_name [lindex $names 1]
	    }
	    3 {
		set middle_name [lindex $names 1]
		if {[string length $middle_name] < 3} {

		    set first_names [lindex $names 0]
		    set last_name [lindex $names 2]

		} else {

		    set first_names "[lindex $names 0] [lindex $names 1]"
		    set last_name [lindex $names 2]

		}
	    }
	}

#	ad_return_complaint 1 "first_names='$first_names', last_name='$last_name', email='$email', name_count=$name_count"

    }
    
    if {![info exists email] || ![util_email_valid_p $email]} {
	append exception_text "<li>Couldn't find a valid email address in ($row).</li>\n"
	continue
    } else {
	set user_exists_p [db_0or1row user_id "select party_id from parties where email = lower(:email)"]
	
	if {$user_exists_p > 0} {

            # Add user to subsite as a member
            
            group::add_member \
                -group_id $group_id \
                -user_id $party_id
            
	    append exception_text "<li> $email was already in the database.</li>\n"

	    continue
	}
    }
    
    if {![info exists first_names] || [empty_string_p $first_names]} {
	append exception_text "<li> No first name in ($row)</li>\n"
	continue
    }
    
    if {![info exists last_name] || [empty_string_p $last_name]} {
	append exception_text "<li> No last name in ($row)</li>\n"
	continue
    }
    
    # We've checked everything.
    
    set password [ad_generate_random_string]
    
    array set auth_status_array [auth::create_user -email $email -first_names $first_names -last_name $last_name -password $password]

    set user_id $auth_status_array(user_id)
    
    append success_text "Created user $user_id for ($row)<br\>"


    # Add user to subsite as a member
    
    group::add_member \
        -group_id $group_id \
        -user_id $user_id
    
    # if anything goes wrong here, stop the whole process
    if { !$user_id } {
	ad_return_error "Insert Failed" "We were unable to create a user record for ($row)."
	ad_script_abort
    }

    # Do this for the sake of the FTI search engine
    db_dml update_persons "
	update persons
	set first_names=first_names
	where person_id=:user_id
    "


    # send email

    if {$send_email_p} {
	set key_list [list first_names last_name email password]
	set value_list [list $first_names $last_name $email $password]
    
	set sub_message $message
	foreach key $key_list value $value_list {
	    regsub -all "<$key>" $sub_message $value sub_message
	}
    
	if {[catch {ns_sendmail "$email" "$from" "$subject" "$sub_message"} errmsg]} {
	    ad_return_error "Mail Failed" "The system was unable to send email.  Please notify the user personally.  This problem is probably caused by a misconfiguration of your email system.  Here is the error: 
<blockquote><pre>
[ad_quotehtml $errmsg]
</pre></blockquote>"
            return
        }
    }
}

ad_return_template


