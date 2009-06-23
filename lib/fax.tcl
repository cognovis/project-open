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
set template_path "[acs_root_dir]/templates/pdf/fax"

set date [split [dt_sysdate] "-"]
append form_elements {
    message_id:key
    party_ids:text(hidden)
    return_url:text(hidden)
    title:text(hidden),optional
    {message_type:text(hidden) {value "fax"}}
    {recipients:text(inform)
	{label "[_ intranet-contacts.Recipients]"}
    }
    {subject:text(text),optional
	{label "[_ intranet-contacts.Subject]"}
	{html {size 55}}
	{help_text {[_ intranet-contacts.fax_subject_help]}}
    }
    {content:richtext(richtext)
	{label "[_ intranet-contacts.oo_message]"}
	{html {cols 70 rows 24}}
	{help_text {[_ intranet-contacts.fax_content_help]}}
    }
    {pages:integer(text),optional
	{label "[_ intranet-contacts.fax_pages]"}
	{html {cols 70 rows 24}}
	{help_text {[_ intranet-contacts.fax_pages_help]}}
    }
    {account_manager_p:text(select)
	{label "[_ intranet-contacts.Account_Manager_P]"}
	{help_text "[_ intranet-contacts.Account_Manager_P_help_text]"}
	{options {{"[_ intranet-contacts.account_manager]" "t"} {"[_ intranet-contacts.yourself]" "f"}}}
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

            # get the user information
            if {[contact::employee::get -employee_id $party_id -array employee]} {
		if {![person::person_p -party_id $party_id]} {
		    set employee(locale) [lang::user::site_wide_locale -user_id $party_id]
		    set organization_id $party_id
		} else {
		    set organization_id $employee(organization_id)
		}
                set date [lc_time_fmt [dt_systime] "%q %X" "$employee(locale)"]
                set regards [lang::message::lookup $employee(locale) intranet-contacts.with_best_regards]
            } else {
                ad_return_error [_ intranet-contacts.Error] [_ intranet-contacts.lt_there_was_an_error_processing_this_request]
                break
            }
	    
	    set fax [ad_html_to_text -no_format $employee(directfaxno)]
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

	    if {![contact::employee::get -employee_id $user_id -array user_info]} {
		ad_return_error $user_id "User is not an employee"
	    }

            set file [open "${template_path}/content.xml"]
            fconfigure $file -translation binary
            set template_content [read $file]
            close $file

            set file [open "${template_path}/styles.xml"]
            fconfigure $file -translation binary
            set style_content [read $file]
            close $file
	    
            eval [template::adp_compile -string $template_content]
            set oo_content $__adp_output

            eval [template::adp_compile -string $style_content]
            set style $__adp_output

	    ns_log debug "Content:: $content"
	    set odt_filename [contact::oo::change_content -path "${template_path}" -document_filename "document.odt" -contents [list "content.xml" $oo_content "styles.xml" $style]]

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
	    
	    # Log that we have been sending this fax
	    contact::message::log \
		-message_type "fax" \
		-sender_id $user_id \
		-recipient_id $party_id \
		-title $title \
		-description "" \
		-content $content \
		-content_format "text/html"
	}	    

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
		    -files [list [list "mailing.pdf" "[lindex $pdf_path 0]" "[lindex $pdf_path 1]"]] \
		    -mime_type "text/plain"
	    } 
	    ad_progress_bar_end -url  [contact::url -party_id $party_id]
	} else {
	    # We are not sending the e-mail but write the file back to the user
	    cr_write_content -revision_id $print_revision_id
	}
    }

