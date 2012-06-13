# packages/contacts/lib/email.tcl
# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14
# @arch-tag: 48fe00a8-a527-4848-b5de-0f76dfb60291
# @cvs-id $Id$

foreach required_param {party_ids recipients} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {return_url} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {[exists_and_not_null header_id]} {
    contact::message::get -item_id $header_id -array header_info
    set header [ad_html_text_convert \
		     -to "text/html" \
		     -from $header_info(content_format) \
		     -- $header_info(content) \
		    ]
} else {
    set header "<div class=\"mailing-address\">{name}<br />
{mailing_address}</div>"
}

if {[exists_and_not_null footer_id]} {
    contact::message::get -item_id $footer_id -array footer_info
    set footer [ad_html_text_convert \
		     -to "text/html" \
		     -from $footer_info(content_format) \
		     -- $footer_info(content) \
		    ]
} else {
    set footer ""
}

set template_path "[acs_root_dir][parameter::get_from_package_key -package_key contacts -parameter OOMailingPath]"
set banner_options [util::find_all_files -extension jpg -path "${template_path}/banner"]

set date [split [dt_sysdate] "-"]
append form_elements {
    message_id:key
    party_ids:text(hidden)
    return_url:text(hidden)
    title:text(hidden),optional
    oo_template_path:text(hidden),optional
    {message_type:text(hidden) {value "oo_mailing"}}
    {recipients:text(inform)
	{label "[_ intranet-contacts.Recipients]"}
    }
    {date:date(date)
	{label "[_ intranet-contacts.Date]"}
    }
}

if {$banner_options eq ""} {
    append form_elements {
	{banner:text(hidden) {value ""}}
    }
} else {
    set banner_options [concat [list ""] $banner_options]
    append form_elements {
	{-section "sec1" {legendtext "[_ intranet-contacts.oo_message]"} {legend {class myClass id myId}}}
	{banner:text(select),optional
	    {label "[_ intranet-contacts.Banner]"} 
	    {help_text "[_ intranet-contacts.Banner_help_text]"}
	    {options $banner_options}
	}
    }
}

append form_elements {
    {mailing_subject:text(text),optional
        {label "[_ intranet-contacts.mailing_subject]"} 
        {help_text "[_ intranet-contacts.mailing_subject_help]"}
        {html {size 45 maxlength 1000}}
    }
    {content:richtext(richtext)
	{label "[_ intranet-contacts.oo_message]"}
	{html {cols 70 rows 24}}
	{help_text {[_ intranet-contacts.oo_content_help]}}
    }
    {ps:text(text),optional
        {label "[_ intranet-contacts.PS]"} 
        {help_text "[_ intranet-contacts.PS_help_text]"}
        {html {size 45 maxlength 1000}}
    }
}


if {0} {
    append form_elements {
	{account_manager_p:text(select)
	    {label "[_ intranet-contacts.Account_Manager_P]"}
	    {help_text "[_ intranet-contacts.Account_Manager_P_help_text]"}
	    {options {{"[_ intranet-contacts.account_manager]" "t"} {"[_ intranet-contacts.yourself]" "f"}}}
	}
    }
} else {
    append form_elements {
	{account_manager_p:text(hidden)
	    {value "0"}
	}
    }
}

append form_elements {
    {-section "sec2" {legendtext "[_ intranet-contacts.oo_email_content]"} {legend {class myClass id myId}}}
    {subject:text(text),optional
	{label "[_ intranet-contacts.Subject]"}
	{html {size 55}}
	{help_text {[_ intranet-contacts.oo_email_subject_help]}}
    }
    {email_content:text(textarea),optional
	{label "[_ intranet-contacts.oo_email_content]"}
	{html {cols 65 rows 12}}
	{help_text {[_ intranet-contacts.oo_email_help]}}
    }
}

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

ad_form -action message \
    -name letter \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -form $form_elements \
    -on_request {
    } -new_request {
 	if {[exists_and_not_null item_id]} {
	    contact::message::get -item_id $item_id -array message_info
	    set subject $message_info(description)
	    set content [ad_html_text_convert \
			     -to "text/html" \
			     -from $message_info(content_format) \
			     -- $message_info(content) \
			    ]
	    set content [list $content $message_info(content_format)]
	    set title $message_info(title)
	    set mailing_subject $title
            set ps $message_info(ps)
            set banner $message_info(banner)
	    set oo_template_path $message_info(oo_template)
	} else {
	    if { [exists_and_not_null signature] } {
		set content [list $signature "text/html"]
	    }
	}
	set paper_type "letterhead"
    } -edit_request {
    } -on_submit {

        # Make sure the content actually exists
	set content_raw [string trim \
			     [ad_html_text_convert \
				  -from [template::util::richtext::get_property format $content] \
				  -to "text/plain" \
				  [template::util::richtext::get_property content $content] \
				 ] \
			    ]
	if {$content_raw == "" } {
	    template::element set_error message content "[_ intranet-contacts.Message_is_required]"
	}
	
	template::multirow create messages revision_id to_addr to_party_id subject content_body

	# We need to set the original date here
	set orig_date $date

	# Number of seconds the PDF takes for the generation
	set seconds_per_user 10
	set num_of_users [llength $party_ids]
	set seconds_to_finish [expr $num_of_users * $seconds_per_user]
	set package_id [ad_conn package_id]
	set pdf_filenames [list]
	
	set from [ad_conn user_id]
	set from_addr [contact::email -party_id $from]
	
	# Now parse the content for openoffice
	set content_format [template::util::richtext::get_property format $content]
	set content [contact::oo::convert -content [string trim [template::util::richtext::get_property content $content]]]
	eval [template::adp_compile -string $content]
	set content $__adp_output


	if {$num_of_users >1} {
	    ad_progress_bar_begin -title "[_ intranet-contacts.Sending_Mailing]" -message_1 "[_ intranet-contacts.lt_We_are_sending_the_mailing]" -message_2 "[_ intranet-contacts.lt_We_will_continue_auto]"
	}

	foreach party_id $party_ids {
	    
	    # Reset the file_ids
	    set file_ids ""

	    set party [::im::dynfield::Class get_instance_from_db -id $party_id]
	    $party address -type "home"
	    $party instvar address_line1 address_line2 city state postal_code country country_code address_name company_name salutation city_line

	    # Retrieve information about the creation user so it can be used in the template
	    # First check if there is an account manager
	    if {[string eq $account_manager_p "t"]} {
		set account_manager_id [contact::util::get_account_manager -organization_id $organization_id]
	    } else {
		set account_manager_id ""
	    }

	    if {[string eq "" $account_manager_id]} {
		set user_id [ad_conn user_id]
	    } else {
		set user_id $account_manager_id
	    }


	    # Format the strings
	    eval [template::adp_compile -string $ps]
	    set ps $__adp_output
	    set ps [contact::oo::convert -content $ps]

            set file [open "${oo_template_path}/content.xml"]
            fconfigure $file -translation binary
            set template_content [read $file]
            close $file

            set file [open "${oo_template_path}/styles.xml"]
            fconfigure $file -translation binary
            set style_content [read $file]
            close $file
	    
            eval [template::adp_compile -string $template_content]
            set oo_content $__adp_output

            eval [template::adp_compile -string $style_content]
            set style $__adp_output

	    ns_log debug "Content:: $content"
	    set odt_filename [contact::oo::change_content -path "${oo_template_path}" -document_filename "document.odt" -contents [list "content.xml" $oo_content "styles.xml" $style]]

	    # Subject is set => we send an email.
	    if {$subject ne ""} {

		# Create the pdf and store it
		set item_id [contact::oo::import_oo_pdf -oo_file $odt_filename -parent_id $party_id -title "${title}.pdf"] 
		set revision_id [content::item::get_best_revision -item_id $item_id]

		set to_addr [contact::message::email_address -party_id $party_id]		
		set values [list]
		if {[person::person_p -party_id $party_id]} {
		    $party instvar first_names last_name 
		    set mailing_address "$to_addr"
		    foreach element [list first_names last_name address_name salutation mailing_address] {
			lappend values [list "{$element}" [set $element]]
		    }
		}

		# Append the file(s)
		if {[exists_and_not_null revision_id]} {
		    set file_ids $revision_id
		}
	    
		# Append the additional files
		if {[exists_and_not_null files_extend]} {
		    foreach file_id $files_extend {
			lappend file_ids $file_id
		    }
		}

		# Send the e-mail to each of the users
		acs_mail_lite::send \
		    -to_addr $to_addr \
		    -from_addr "$from_addr" \
		    -subject "[contact::message::interpolate -text $subject -values $values]" \
		    -body "[contact::message::interpolate -text $email_content -values $values]" \
		    -package_id $package_id \
		    -file_ids $file_ids \
		    -mime_type "text/plain"
	    } else {
		if {$num_of_users > 1} {
		    set pdf_filename [contact::oo::import_oo_pdf -oo_file $odt_filename -parent_id $party_id -title "${title}.pdf" -return_pdf] 
		    if {[string eq [lindex $pdf_filename 0] "application/pdf"]} {
			lappend pdf_filenames [lindex $pdf_filename 1]
		    } else {
			ns_log Error "could not generate PDF for $odt_filename"
		    }
		} else {
		    set print_item_id [contact::oo::import_oo_pdf -oo_file $odt_filename -parent_id $party_id -title "${title}.pdf"] 
		    set print_revision_id [content::item::get_best_revision -item_id $print_item_id]
		}
	    }

	    # Log that we have been sending this oo-mailing
	    contact::message::log \
		-message_type "oo_mailing" \
		-sender_id $user_id \
		-recipient_id $party_id \
		-title $title \
		-description "" \
		-content $content \
		-content_format "text/html"
	}	    

	if {$subject eq ""} {
	    if {$num_of_users > 1} {
		if {[llength $pdf_filenames] > 1} {
		    # We are not sending the e-mail but write the file as an email back to the user
		    set pdf_path [contact::oo::join_pdf -filenames $pdf_filenames -parent_id $user_id -title "mailing.pdf" -no_import] 
		    
		    # We are sending the mail from and to the same user. This is why from_addr = to_addr
		    acs_mail_lite::send \
			-to_addr $from_addr \
			-from_addr "$from_addr" \
			-subject "Joined PDF attached" \
			-body "See attached file" \
			-package_id $package_id \
			-file_ids $print_item_id \
			-mime_type "text/plain"
		} 
	    } else {
		# We are not sending the e-mail but write the file back to the user
		ns_log Notice "TEST:: $print_revision_id"
		ad_returnredirect "/file/${print_item_id}/mailing.pdf"
	    }
	}
	
	if {$num_of_users > 1} {
	    ad_progress_bar_end -url  [contact::url -party_id $party_id]
	} else {
	    ad_returnredirect [contact::url -party_id $party_id]
	}

    }

