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

set template_path "[acs_root_dir]/templates/pdf/werbemailing/"

set date [split [dt_sysdate] "-"]
append form_elements {
    message_id:key
    party_ids:text(hidden)
    return_url:text(hidden)
    title:text(hidden),optional
    {message_type:text(hidden) {value "werbemailing"}}
    {recipients:text(inform)
	{label "[_ intranet-contacts.Recipients]"}
    }
    {date:date(date)
	{label "[_ intranet-contacts.Date]"}
    }
    {subject:text(text),optional
	{label "[_ intranet-contacts.Subject]"}
	{html {size 55}}
	{section "[_ intranet-contacts.oo_email_content]"}
	{help_text {[_ intranet-contacts.oo_email_subject_help]}}
    }
    {email_content:text(textarea),optional
	{label "[_ intranet-contacts.oo_email_content]"}
	{html {cols 65 rows 12}}
	{help_text {[_ intranet-contacts.oo_email_help]}}
    }
}

ad_form -action message \
    -name letter \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -form $form_elements \
    -on_request {
    } -new_request {
    } -edit_request {
    } -on_submit {

	template::multirow create messages revision_id to_addr to_party_id subject content_body

	set file_revisions [list]
	
	# We need to set the original date here
	set orig_date $date

	foreach party_id $party_ids {

            # get the user information
            if {[contact::employee::get -employee_id $party_id -array employee]} {
		if {![person::person_p -party_id $party_id]} {
		    set employee(locale) [lang::user::site_wide_locale -user_id $party_id]
		    set organization_id $party_id
		} else {
		    set organization_id $employee(organization_id)
		}
                set date [lc_time_fmt [join [template::util::date::get_property linear_date_no_time $orig_date] "-"] "%q" "$employee(locale)"]
		set date_7 [lc_time_fmt [clock format [clock scan {+7 days}] -format "%Y-%m-%d"] "%q" "$employee(locale)"]
		set date_14 [lc_time_fmt [clock format [clock scan {+14 days}] -format "%Y-%m-%d"] "%q" "$employee(locale)"]
		set regards [lang::message::lookup $employee(locale) contacts.with_best_regards]
            } else {
                ad_return_error [_ intranet-contacts.Error] [_ intranet-contacts.lt_there_was_an_error_processing_this_request]
                break
            }
	    
	    # Retrieve information about the creation user so it can be used in the template
	    # First check if there is an account manager
	    set account_manager_id [contact::util::get_account_manager -organization_id $organization_id]
	    if {[string eq "" $account_manager_id]} {
		set user_id [ad_conn user_id]
	    } else {
		set user_id $account_manager_id
	    }

	    if {![contact::employee::get -employee_id $user_id -array user_info]} {
		ad_return_error $user_id "User is not an employee"
	    }
	    
	    set employee(name) [encoding convertto utf-8 $employee(name)]
            set file [open "${template_path}/content.xml"]
            fconfigure $file -translation binary
            set template_content [read $file]
            close $file

            set file [open "${template_path}/styles.xml"]
            fconfigure $file -translation binary
            set style_content [read $file]
            close $file
	    
            eval [template::adp_compile -string $template_content]
            set content $__adp_output

            eval [template::adp_compile -string $style_content]
            set style $__adp_output

	    set odt_filename [contact::oo::change_content -path "${template_path}" -document_filename "document.odt" -contents [list "content.xml" $content "styles.xml" $style] -encoding "iso8859-1"]
	    set title "werbemailing"
	    set item_id [contact::oo::import_oo_pdf -oo_file $odt_filename -parent_id $party_id -title "${title}.pdf"] 
	    set revision_id [content::item::get_best_revision -item_id $item_id]
	    lappend file_revisions $revision_id

	    # Now we need to find a way to join all these files. Probably using a new procedure to join all the revision ids
	    
	    # Subject is set => we send an email.
	    if {$subject ne ""} {

		# Differentiate between person and organization
		if {[person::person_p -party_id $party_id]} {
		    contact::employee::get -employee_id $party_id -array employee
		    set first_names $employee(first_names)
		    set last_name $employee(last_name)
		    set name [string trim "$employee(person_title) $first_names $last_name"]
		    set salutation $employee(salutation)
		    set directphone $employee(directphoneno)
		    set mailing_address $employee(mailing_address)
		    set locale $employee(locale)
		    set to_addr $employee(email)
		} else {
		    set name [contact::name -party_id $party_id]
		    set to_addr [contact::message::email_address -party_id $party_id]
		    set salutation "Dear ladies and gentlemen"
		    set locale [lang::user::site_wide_locale -user_id $party_id]
		}
		
		set values [list]
		foreach element [list first_names last_name name date salutation mailing_address directphone] {
		    lappend values [list "{$element}" [set $element]]
		}
		
		# We are going to create a multirow which knows about the file (revision_id) and contains
		# the parsed e-mail.
		set to_addr [contact::message::email_address -party_id $party_id]
		template::multirow append messages $revision_id $to_addr "" [contact::message::interpolate -text $subject -values $values] [contact::message::interpolate -text $email_content -values $values]
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

	if {$subject ne ""} {
	    set from [ad_conn user_id]
	    set from_addr [contact::email -party_id $from]
	    set package_id [ad_conn package_id]

	    template::multirow foreach messages {

		# Send the e-mail to each of the users
		acs_mail_lite::send \
		    -to_addr $to_addr \
		    -from_addr "$from_addr" \
		    -subject "$subject" \
		    -body "$content_body" \
		    -package_id $package_id \
		    -file_ids $revision_id \
		    -mime_type "text/plain" 
	    }
	} else {
	    
	    # We are not sending the e-mail but write the file back to the user
	    if {[llength $file_revisions]>=1} {
		cr_write_content -revision_id [lindex $file_revisions 0]
	    }
	}
	ad_returnredirect [contact::url -party_id $party_id]
    }

