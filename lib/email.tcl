# packages/contacts/lib/email.tcl
# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14
# @arch-tag: 48fe00a8-a527-4848-b5de-0f76dfb60291
# @cvs-id $Id$

foreach required_param {party_ids} {
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

# Somehow when the form is submited the party_ids values became
# only one element of a list, this avoid that problem

set recipients [list]
foreach party_id $party_ids {
    if {![empty_string_p $party_id]} {
	lappend recipients [list "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a> ([contact::message::email_address -party_id $party_id])" $party_id]
    }
}

# The element check_uncheck only calls a javascript function
# to check or uncheck all recipients
set recipients_num [llength $recipients]
if { $recipients_num <= 1 } {
    set form_elements {
	message_id:key
	return_url:text(hidden)
	title:text(hidden),optional
	{message_type:text(hidden) {value "email"}}
	{-section "sec1" {legendtext "[_ intranet-contacts.Recipients]"}}
	{to:text(checkbox),multiple,optional
	    {label "[_ intranet-contacts.Recipients]"} 
	    {options  $recipients }
	    {html {checked 1}}
	}
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
} else {
    set form_elements {
	message_id:key
	return_url:text(hidden)
	title:text(hidden),optional
	{message_type:text(hidden) {value "email"}}
	{-section "sec1" {legendtext "[_ intranet-contacts.Recipients]"}}
	{check_uncheck:text(checkbox),multiple,optional
	    {label "[_ intranet-contacts.check_uncheck]"}
	    {options {{"" 1}}}
	    {html {onclick check_uncheck_boxes(this.checked)}}
	}
	{to:text(checkbox),multiple,optional
	    {label "[_ intranet-contacts.Recipients]"} 
	    {options  $recipients }
	    {html {checked 1}}
	}
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
        {files:text(inform),optional {label "[_ acs-mail-lite.Associated_files]"} {value $files}}
    }
}

append form_elements {
    {context_id:text(hidden) {value $context_id}}
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
	{help_text "[_ intranet-contacts.lt_remember_that_you_can]"}
	{value $content_list}
    }
    {upload_file:file(file),optional
	{label "[_ intranet-contacts.Upload_file]"}
    }
    {mail_through_p:integer(radio)
	{label "[_ intranet-contacts.Mail_through_p]"}
	{options {{"Yes" "1"} {"No" "0"}}}
	{value "1"}
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
	
	    # List to store know wich emails recieved the message
	    set recipients_addr [list]

	    set from [ad_conn user_id]
	    set from_addr [contact::email -party_id $from]

	    # Remove all spaces in cc and bcc
	    regsub -all " " $cc "" cc
	    regsub -all " " $bcc "" bcc

	    set cc_list [split $cc ";"]
	    set bcc_list [split $bcc ";"]

	    set mime_type [template::util::richtext::get_property format $content_body]
	    set content_body [template::util::richtext::get_property contents $content_body]


	    # Insert the uploaded file linked under the package_id
	    set package_id [ad_conn package_id]
	
	    if {![empty_string_p $upload_file] } {
	        set revision_id [content::item::upload_file \
				    -package_id $package_id \
				    -upload_file $upload_file \
				    -parent_id $party_id]

	        lappend file_ids $revision_id
	    }
	
	    # Append the additional files
	    if {[exists_and_not_null files_extend]} {
	        foreach file_id $files_extend {
		        lappend file_ids $file_id
	        }
	    }
	
	
	    # Send the mail to all parties.

	    foreach party_id $to {
            # Get the party
            
            set party [::im::dynfield::Class get_instance_from_db -id $party_id]

	        set values [list]
	        foreach element [list first_names last_name name] {
		        lappend values [list "{$element}" [$party $element]]
	        }
            set name [$party name]
	        lappend values [list "salutation" "[$party set salutation_id_deref]"]

	        set interpol_subject [contact::message::interpolate -text $subject -values $values]

	        set interpol_content_body [contact::message::interpolate -text $content_body -values $values]
	    
	        # If we are doing mail through for tracking purposes
	        # Set the reply_to_addr accordingly
	        if {$mail_through_p} {
		        regsub -all {@} $from_addr {#} reply_to
		        set reply_to_addr "${reply_to}@[acs_mail_lite::address_domain]"
	        } else {
		        set reply_to_addr $from_addr
	        }

	        ns_log Notice "SENDING Recipients: $party_id"

	        acs_mail_lite::complex_send \
		        -to_party_ids $party_id \
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
	            lappend recipients "<a href=\"[contact::url -party_id $party_id]\">$name</a>"
	        }

	    if {$to eq ""} {
	        acs_mail_lite::complex_send \
		    -cc_addr $cc_list \
		    -bcc_addr $bcc_list \
		    -from_addr "$from_addr" \
		    -subject "$subject" \
		    -body "$content_body" \
		    -package_id $package_id \
		    -file_ids $file_ids \
		    -mime_type $mime_type \
		    -object_id $context_id \
		    -single_email
	    }

	    ad_returnredirect $return_url
	
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

    } -after_submit {
	    ad_script_abort
    }

