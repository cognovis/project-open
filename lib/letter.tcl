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
}

if {[exists_and_not_null footer_id]} {
    contact::message::get -item_id $footer_id -array footer_info
    set footer [ad_html_text_convert \
		     -to "text/html" \
		     -from $footer_info(content_format) \
		     -- $footer_info(content) \
		    ]
}


    
set date [split [dt_sysdate] "-"]
append form_elements {
    message_id:key
    party_ids:text(hidden)
    return_url:text(hidden)
    title:text(hidden),optional
    {message_type:text(hidden) {value "letter"}}
    {paper_type:text(select),optional
	{label "[_ intranet-contacts.Paper_Type]"}
	{options {{"[_ intranet-contacts.Letter]" letter} {"[_ intranet-contacts.Letterhead]" letterhead}}}
    }
    {recipients:text(inform)
	{label "[_ intranet-contacts.Recipients]"}
	{help_text {[_ intranet-contacts.lt_The_recipeints_name_a]}}
    }
    {date:date(date),optional
	{label "[_ intranet-contacts.Date]"}
    }
    {include_address:boolean(checkbox),optional
        {label ""}
        {options "[list [list [_ intranet-contacts.Include_address_for_windowed_] 1]]"}
    }
    {header:text(inform),optional
	{label "[_ intranet-contacts.Header]"}
    }
    {content:richtext(richtext)
	{label "[_ intranet-contacts.Message]"}
	{html {cols 70 rows 24}}
	{help_text {[_ intranet-contacts.lt_remember_that_you_can]}}
    }
    {footer:text(inform),optional
	{label "[_ intranet-contacts.Footer]"}
    }
}

ad_form -action message \
    -name letter \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons [list [list [_ intranet-contacts.Print] print]] \
    -form $form_elements \
    -on_request {
	set include_address "1"
    } -new_request {
 	if {[exists_and_not_null signature_id]} {
	    set signature [contact::signature::get -signature_id $signature_id]
	}
 	if {[exists_and_not_null item_id]} {
	    contact::message::get -item_id $item_id -array message_info
	    set subject $message_info(description)
	    set content $message_info(content)
	    if { [exists_and_not_null signature] } {
		if { $message_info(content_format) == "text/html" } {
		    # if there is a signature we need to convert
		    # if not we let "reformatting" be handled by
		    # whatever richtext widget is used on the
		    # since we don't know what it is
		    set signature [ad_html_text_convert -to "text/html" -from "text/plain" -- $signature]
		    append content "\n<p><br />${signature}</p>"
		} else {
		    append content "\n\n${signature}"   
		}
	    }
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
	set user_id [ad_conn user_id]
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
	set content_html [ad_html_text_convert \
			      -from [template::util::richtext::get_property format $content] \
			      -to "text/html" \
			      -- [string trim [template::util::richtext::get_property content $content]] \
			      ]
	if { [exists_and_not_null header] } {
	    set content_html "${header}\n\n${content_html}"
	}
	if { [exists_and_not_null footer] } {
	    set content_html "${content_html}\n\n${footer}"
	}

	set messages [list]
	set date [join [template::util::date::get_property linear_date_no_time $date] "-"]

	if { $include_address eq "1" } {
	    set message_class "message"
        } else {
	    set messege_class "message noaddress"
	}
        set count 1
        set total_count [llength $party_ids]

	foreach party_id $party_ids {

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
	    } else {
		set name [contact::name -party_id $party_id]
		set salutation "Dear ladies and gentlemen"
		set locale [lang::user::site_wide_locale -user_id $party_id]
	    }

	    set letter ""
	    if { [exists_and_not_null date] } {
		# do not pull the date variable out here and reformat
                # the date is reformatted every time and depends on
                # it being in the linear_date_not_time format specified
                # above
		append letter "\n<div class=\"date\">[lc_time_fmt $date %q $locale]</div>"
	    }
	    if { $include_address eq "1" } {
		# this work differnt from the contact::employee::get mailing address because that is
		# in text format, but we need it as html
		append letter "\n<div class=\"mailing-address\">$name<br />[contact::message::mailing_address -party_id $party_id -format "text/html"]</div>"
	    }
	    append letter "\n<div class=\"content\">${content_html}</div>"
	    set values [list]
	    foreach element [list first_names last_name name date salutation mailing_address directphone] {
		lappend values [list "{$element}" [set $element]]
	    }
	    set letter [contact::message::interpolate -text $letter -values $values]

	    if { $count < $total_count } {
		# we need to do a page break
		lappend messages "<div class=\"${message_class}\" style=\"page-break-after: always;\">\n$letter\n</div>"
	    } else {
		lappend messages "\n\n<div class=\"${message_class}\" style=\"page-break-after: auto;\">\n$letter\n</div>"
	    }
	    incr count
	    contact::message::log \
		-message_type "letter" \
		-sender_id $user_id \
		-recipient_id $party_id \
		-title $title \
		-description "" \
		-content "<div class=\"message\">\n$letter\n</div>" \
		-content_format "text/html"


	}
	
	# onLoad=\"window.print()\"

	# if you want to alter the formatting and are
        # working out of cvs.openacs.org you should use
        # a new css file that is site specified. many
        # contacts sites depend on this markup so please
        # be kind and use CSS.

        # included in this page are a number of css print
        # pages you can use please check them out in 
        # /packages/intranet-contacts/www/resources/

	set labels_url [export_vars -base "message" -url {{message_type label} party_ids return_url}]
        set envelopes_url [export_vars -base "message" -url {{message_type envelope} party_ids return_url}]

	if { [llength $messages] > 1 } {
	    set todo_message [_ intranet-contacts.lt_Once_done_printing_plural]
	} else {
	    set todo_message [_ intranet-contacts.lt_Once_done_printing_singular]
	}

	set css_file [parameter::get -parameter "LetterPrintCSSFile" -default "/resources/contacts/contacts-print.css"]
	ns_return 200 text/html "
<html>
<head>
<title>[_ intranet-contacts.Print_Letter]</title>
<link rel=\"stylesheet\" type=\"text/css\" href=\"${css_file}\">
</head>
<body id=\"${paper_type}\">
<div id=\"header\">
$todo_message
</div>

[join $messages "\n"]

</body>
</html>
"
        ad_script_abort
    }



if { [template::element::get_value letter header] eq "" } {
    template::element::set_properties letter header widget hidden
}
if { [template::element::get_value letter footer] eq "" } {
    template::element::set_properties letter footer widget hidden
}
