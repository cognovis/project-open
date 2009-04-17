# packages/contacts/lib/email.tcl
# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14
# @arch-tag: 48fe00a8-a527-4848-b5de-0f76dfb60291
# @cvs-id $Id$

foreach required_param {search_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}

foreach optional_param {return_url content export_vars file_ids cc bcc item_id context_id} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {![info exists cancel_url]} {
    set cancel_url $return_url
}

if {![info exists no_callback_p]} {
    set no_callback_p f
}

if { [contact::group::notifications_p -group_id $search_id] } {
    set recipients_label [_ intranet-contacts.Notify]
    # we cannot do interpolation with notifications since
    # only one notification is generated for all recipients
    set content_body_help_text ""
} else {
    set recipients_label [_ intranet-contacts.Recipients]
    # since each message is dealt with individually we can
    # do interpolation
    set content_body_help_text [_ intranet-contacts.lt_remember_that_you_can]
}

# The element check_uncheck only calls a javascript function
# to check or uncheck all recipients
set form_elements {
    message_id:key
    return_url:text(hidden)
    no_callback_p:text(hidden)
    title:text(hidden),optional
    search_id:text(hidden)
    {message_type:text(hidden) {value "email"}}
    {-section "sec1" {legendtext "$recipients_label"}}
    {recipients:text(inform)
	{label "$recipients_label"} 
	{value "$recipients"}
    }
}

if { [contact::group::notifications_p -group_id $search_id] } {

    # CC and BCC are not avalable for notifications
    append form_elements {
	{cc:text(hidden),optional}
	{bcc:text(hidden),optional}
    }

} else {

    append form_elements {
	{cc:text(text),optional
	    {label "[_ intranet-contacts.CC]:"} 
	    {html {size 60}}
	    {help_text "[_ intranet-contacts.cc_help]"}
	}
	{bcc:text(text),optional
	    {label "[_ acs-mail-lite.BCC]:"} 
	    {html {size 60}}
	    {help_text "[_ intranet-contacts.cc_help]"}
	}
    }

}

# Set single_email_p in the form
set single_email_p 0

# Get the list of files from the file storage folder
set file_folder_id [parameter::get_from_package_key -package_key "acs-mail-lite" -parameter "FolderID"]
if {![string eq "" $file_folder_id]} {
    # get the list of files in an option
    set file_options [db_list_of_lists files {
	select r.title, i.item_id
	from cr_items i, cr_revisions r
	where i.parent_id = :file_folder_id
	and i.content_type = 'file_storage_object'
	and r.revision_id = i.latest_revision
    }]
    if {![string eq "" $file_options]} {
	append form_elements {
	    {files_extend:text(checkbox),optional 
		{label "[_ acs-mail-lite.Additional_files]"}
		{options $file_options}
	    }
	}
    }
}

# See if the contacts and mail-tracking packages are installed.
set contacts_p [apm_package_installed_p "contacts"]
set tracking_p [apm_package_installed_p "mail-tracking"]

if { [exists_and_not_null file_ids] } {
    set files [list]
    foreach file $file_ids {
	set file_item_id [content::revision::item_id -revision_id $file] 
	if {$file_item_id eq ""} {
	    set file_item_id $file
	}
	set file_title [lang::util::localize [content::item::get_title -item_id $file_item_id]]
	if {[empty_string_p $file_title]} {
	    set file_title "empty"
	}
	if { $tracking_p } {
	    lappend files "<a href=\"/tracking/download/$file_title?file_id=$file_item_id\">$file_title</a> "
	} else {
	    lappend files "$file_title "
	}
    }
    set files [join $files ", "]

    append form_elements {
        {file_ids:text(hidden) {value $file_ids}}
        {context_id:text(hidden) {value $context_id}}
        {files:text(inform),optional {label "[_ acs-mail-lite.Associated_files]"} {value $files}}
    }
}

foreach var $export_vars {
    upvar $var var_value

    # We need to split to construct the element with two lappends
    # becasue if we put something like this {value $value} the value
    # of the variable is not interpreted

    set element [list]
    lappend element "${var}:text(hidden)"
    lappend element "value $var_value"
    
    # Adding the element to the form
    lappend form_elements $element
}

if {![exists_and_not_null mime_type]} {
    set mime_type text/plain
}

set content_list [list $content $mime_type]

append form_elements {
    {-section "sec2" {legendtext "[_ intranet-contacts.Message]"}}
    {subject:text(text),optional
	{label "[_ intranet-contacts.Subject]"}
	{html {size 60}}
    }
    {content_body:richtext(richtext),optional
	{label "[_ intranet-contacts.Message]"}
	{html {cols 80 rows 18}}
	{help_text "$content_body_help_text"}
	{value $content_list}
    }
    {upload_file:file(file),optional
	{label "[_ intranet-contacts.Upload_file]"}
    }
    {mail_through_p:text(hidden)
	{label "[_ intranet-contacts.Mail_through_p]"}
	{options {{"Yes" "1"} {"No" "0"}}}
	{value "0"}
	{help_text "[_ intranet-contacts.lt_Mail_through_p_help]"}
    }
}

if { [exists_and_not_null item_id] } {
    append form_elements {
	{item_id:text(hidden),optional
	    {value $item_id}
	}
    }
}

if { ![exists_and_not_null action] } {
    set action [ad_conn url]
}

set edit_buttons [list [list [_ intranet-contacts.Send] send]]

ad_form -action $action \
    -html {enctype multipart/form-data} \
    -name email \
    -cancel_label "[_ acs-kernel.common_Cancel]" \
    -cancel_url $cancel_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -new_request {
	if {![exists_and_not_null mime_type]} {
	    set mime_type "text/html"
	}

	if {[exists_and_not_null folder_id] } {
	    callback contacts::email_subject -folder_id $folder_id
	}
	if {[exists_and_not_null item_id] } {
	    contact::message::get -item_id $item_id -array message_info
	    set subject $message_info(description)
	    set content_body [list $message_info(content) $message_info(content_format)]
	    set title $message_info(title)
	}
	if {[exists_and_not_null signature_id] } {
	    set signature [contact::signature::get -signature_id $signature_id]
	    if { [exists_and_not_null signature] } {
		append content_body "{<br><br> $signature } text/html"
	    }
	}
    } -edit_request {
	if {![exists_and_not_null mime_type]} {
	    set mime_type "text/html"
	}
	
    } -on_submit {

	set package_id [ad_conn package_id]

	set mime_type [template::util::richtext::get_property format $content_body]
	set content_body [template::util::richtext::get_property contents $content_body]


	# Insert the uploaded file linked under the package_id
	if {![empty_string_p $upload_file] } {
	    set revision_id [content::item::upload_file \
				 -package_id $package_id \
				 -upload_file $upload_file \
				 -parent_id $search_id]

	    lappend file_ids $revision_id
	}
	
	# Append the additional files
	if {[exists_and_not_null files_extend]} {
	    foreach file_id $files_extend {
		lappend file_ids $file_id
	    }
	}



	

	if { [contact::group::notifications_p -group_id $search_id] } {

	    permission::require_permission -object_id $search_id -privilege "write"		

	    notification::new \
		-type_id [notification::type::get_type_id -short_name contacts_group_notif] \
		-object_id $search_id \
		-notif_subject $subject \
		-notif_text [ad_html_text_convert -from $mime_type -to text/plain -- $content_body] \
		-notif_html [ad_html_text_convert -from $mime_type -to text/html -- $content_body] \
		-file_ids $file_ids

	} else {
	
	
	    # Make sure we get the correct users and can send an e-mail to them
	    if {[contact::group::mapped_p -group_id $search_id]} {
		
		# Make sure the user has write permission on the group
		permission::require_permission -object_id $search_id -privilege "write"		
		set valid_party_ids [group::get_members -group_id $search_id]
	    } else {
		set valid_party_ids [contact::search::results -search_id $search_id -package_id $package_id]
	    }
	    
	    set party_ids [list]
	    set invalid_party_ids [list]
	    set invalid_recipients [list]
	    foreach party_id $valid_party_ids {
		if { [party::email -party_id $party_id] eq "" } {
		    # We are going to check if there is an employee relationship
		    # if there is we are going to check if the employer has an
		    # email adrres, if it does we are going to use that address
		    set employer_id [lindex [contact::util::get_employee_organization -employee_id $party_id] 0]
		    
		    if { ![empty_string_p $employer_id] } {
			set emp_addr [contact::email -party_id $employer_id]
			if { ![empty_string_p $emp_addr] } {
			    lappend party_ids $employer_id
			} else {
			    lappend invalid_party_ids $party_id
			}
		    } else {
			lappend invalid_party_ids $party_id
		    }
		} else {
		    lappend party_ids $party_id
		} 
	    }
	    
	    # Deal with the invalid recipients
	    foreach party_id $invalid_party_ids {
		set contact_name   [contact::name -party_id $party_id]
		set contact_url    [contact::url -party_id $party_id]
		lappend invalid_recipients   "<a href=\"${contact_url}\">${contact_name}</a>"
	    }
	    
	    set invalid_recipients [join $invalid_recipients ", "]
	    if { [llength $invalid_recipients] > 0 } {
		switch $message_type {
		    letter {
			set error_message [_ intranet-contacts.lt_You_cannot_send_a_letter_to_invalid_recipients]
		    }
		    email {
			set error_message [_ intranet-contacts.lt_You_cannot_send_an_email_to_invalid_recipients]
		    }
		    default {
			set error_message [_ intranet-contacts.lt_You_cannot_send_a_message_to_invalid_recipients]
		    }
		}
		if { $party_ids != "" } {
		    util_user_message -html -message $error_message
		}
	    }
	    
	    # We get the attribute_id of the salutation attribute
	    set attribute_id [attribute::id -object_type "person" -attribute_name "salutation"]
	    
	    # List to store know wich emails recieved the message
	    set recipients_addr [list]
	    
	    set from [ad_conn user_id]
	    set from_addr [contact::email -party_id $from]
	    
	    # Remove all spaces in cc and bcc
	    regsub -all " " $cc "" cc
	    regsub -all " " $bcc "" bcc
	    
	    set cc_list [split $cc ";"]
	    set bcc_list [split $bcc ";"]
	    
	    # Send the mail to all parties.
	    set member_size [llength $party_ids]
	    set counter 1

	    foreach party_id $party_ids  {
		
		# Differentiate between person and organization
		if {[person::person_p -party_id $party_id]} {
		    set salutation [contact::salutation -party_id $party_id]
		    db_1row names "select first_names, last_name from persons where person_id = :party_id"
		    set name "$first_names $last_name"
		} else {
		    set name [contact::name -party_id $party_id]
		    set salutation "Dear ladies and gentlemen"
		    # the following is a hot fix (nfl 2006/10/20)
		    set first_names ""
		    set last_name ""
		}
		
	        set username [db_string user "select username from users where user_id = :party_id" -default ""]

		set date [lc_time_fmt [dt_sysdate] "%q"]
		
		set values [list]
		foreach element [list first_names last_name salutation name date username] {
		    lappend values [list "{$element}" [set $element]]
		}
		
		set interpol_subject [contact::message::interpolate -text $subject -values $values]
		
		set interpol_content_body [contact::message::interpolate -text $content_body -values $values]
		
		# If we are doing mail through for tracking purposes
		# Set the reply_to_addr accordingly
		if { [string is true $mail_through_p] } {
		    regsub -all {@} $from_addr {#} reply_to
		    set reply_to_addr "${reply_to}@[acs_mail_lite::address_domain]"
		} else {
		    set reply_to_addr $from_addr
		}
		      
		ns_log Notice "Recipient: $name $party_id ( $counter / $member_size )"
		incr counter
		
		acs_mail_lite::send \
			-to_addr [party::email -party_id $party_id] \
		    -cc_addr $cc_list \
		    -bcc_addr $bcc_list \
		    -from_addr "$from_addr" \
		    -reply_to "$reply_to_addr" \
		    -subject "$interpol_subject" \
		    -body "$interpol_content_body" \
		    -package_id $package_id \
		    -file_ids $file_ids \
		    -mime_type $mime_type \
		    -object_id $context_id \
		    -no_callback_p $no_callback_p \
		    -single_email
		
		# Link the files to all parties
		if {[exists_and_not_null revision_id]} {
		    application_data_link::new -this_object_id $revision_id -target_object_id $party_id
		}
		
		# Log the sending of the mail in contacts history
		if { ![empty_string_p $item_id]} {
		    
		    contact::message::log \
			-message_type "email" \
			-sender_id $from \
			-recipient_id $party_id \
			-title $title \
			-description $subject \
			-content $content_body \
			-content_format "text/plain" \
			-item_id "$item_id"
			
		}
	    }
		
		
		
	
	    # Prepare the user message
	    foreach cc_addr [concat $cc_list $bcc_list] {
		set cc_id [party::get_by_email -email $cc_addr]
		if {$cc_id eq ""} {
		    lappend recipients $cc_addr
		} else {
		    lappend recipients "<a href=\"[contact::url -party_id $cc_id]\">[contact::name -party_id $cc_id]</a>"
		}
	    }
	    util_user_message -html -message "[_ intranet-contacts.Your_message_was_sent_to_-recipients-]"

	}
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }

