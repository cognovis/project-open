# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14

foreach required_param {} {
    if {![info exists $required_param]} {
        return -code error "$required_param is a required parameter."
    }
}

foreach optional_param {return_url content export_vars file_ids object_id cc item_id cc_ids to to_addr party_ids} {
    if {![info exists $optional_param]} {
        set $optional_param {}
    }
}

if {![info exists mime_type]} {
    set mime_type "text/html"
}
if {![info exists cancel_url]} {
    set cancel_url $return_url
}

if {![info exists no_callback_p]} {
    set no_callback_p f
}

# Somehow when the form is submited the party_ids values became
# only one element of a list, this avoid that problem

set recipients [list]
foreach party_id $party_ids {
    if {![empty_string_p $party_id]} {
	    lappend recipients [list "[party::name -party_id $party_id]</a> ([cc_email_from_party $party_id])" $party_id]
	}
}

set cc_recipients [list]
foreach cc_id $cc_ids {
    if {![empty_string_p $cc_id]} {
	    lappend cc_recipients [list "[party::name -party_id $cc_id]</a> ([cc_email_from_party $cc_id])" $cc_id]
	}
}

set form_elements {
    message_id:key
    return_url:text(hidden),optional
    no_callback_p:text(hidden)
    title:text(hidden),optional
    {message_type:text(hidden) {value "email"}}
    {-section "recipients" {legendtext "[_ acs-mail-lite.Recipients]"}}
}

if {$recipients eq ""} {
    append form_elements {
	{to_addr:text(text)
	    {label "[_ acs-mail-lite.Recipients]:"} 
	    {html {size 56}}
	    {help_text "[_ acs-mail-lite.cc_help]"}
	}
    }
} else {
    append form_elements {
	{to:text(checkbox),multiple
	    {label "[_ acs-mail-lite.Recipients]:"} 
	    {options  $recipients }
	    {html {checked 1}}
	}
	{to_addr:text(text),optional
	    {label "[_ acs-mail-lite.Recipients]:"} 
	    {html {size 56}}
	    {help_text "[_ acs-mail-lite.cc_help]"}
	}
    }
}

if {$cc_recipients ne ""} {
    append form_elements {
        {cc_ids:text(checkbox),multiple,optional
            {label "[_ acs-mail-lite.CC]:"} 
            {options  $cc_recipients }
            {html {checked 0}}
        }
    } 
}

append form_elements {
    {cc_addr:text(text),optional
        {label "[_ acs-mail-lite.CC]:"} 
        {html {size 56}}
        {help_text "[_ acs-mail-lite.cc_help]"}
    }
    {-section ""}
}


if { [exists_and_not_null file_ids] } {
    set files [list]
    foreach file $file_ids {
        set file_title [lang::util::localize [db_string get_file_title { } -default "[_ acs-mail-lite.Untitled]"]]
        if { $tracking_p } {
            lappend files "<a href=\"/tracking/download/$file_title?version_id=$file\">$file_title</a> "
        } else {
            lappend files "$file_title "
        }
    }
    set files [join $files ", "]
    
    append form_elements {
        {files_ids:text(inform),optional {label "[_ acs-mail-lite.Associated_files]"} {value $files}}
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

set content_list [list $content $mime_type]

append form_elements {
	{-section "message" {legendtext "[_ acs-mail-lite.Message]"}}
    {subject:text(text),optional
	{label "[_ acs-mail-lite.Subject]"}
        {html {size 55}}
    }
    {content_body:text(richtext),optional
        {label "[_ acs-mail-lite.Message]"}
        {html {cols 55 rows 18}}
        {value $content_list}
    }
    {upload_file:file(file),optional
        {label "[_ acs-mail-lite.Upload_file]"}
    }
	{-section ""}
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

set edit_buttons [list [list [_ acs-mail-lite.Send] send]]

ad_form -action $action \
    -html {enctype multipart/form-data} \
    -name email \
    -cancel_label "[_ acs-kernel.common_Cancel]" \
    -cancel_url $cancel_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -new_request {
    } -edit_request {
    } -on_submit {
        # List to store know wich emails recieved the message
        set recipients_addr [list]
        
        set from [ad_conn user_id]
        set from_addr [cc_email_from_party $from]
        
        # Remove all spaces in cc
        regsub -all " " $cc_addr "" cc_addr
        
        set cc_addr [split $cc_addr ";"]
        set to_addr [split $to_addr ";"]

        # Insert the uploaded file linked under the package_id
        set package_id [ad_conn package_id]
        
        if {![empty_string_p $upload_file] } {
            set revision_id [content::item::upload_file \
                                 -package_id $package_id \
                                 -upload_file $upload_file \
                                 -parent_id $party_id]
        }
        
        if {[exists_and_not_null revision_id]} {
            if {[exists_and_not_null file_ids]} {
                append file_ids " $revision_id"
            } else {
                set file_ids $revision_id
            }
        }

        
        foreach party_id $to {
            set email [cc_email_from_party $party_id]
            # Check if the cc_ids is already there
            if {[lsearch $to_addr $email]<0} {
                lappend to_addr $email
            }
        }

        foreach party_id $cc_ids {
            set email [cc_email_from_party $party_id]
            # Check if the cc_ids is already there
            if {[lsearch $cc_addr $email]<0} {
                lappend cc_addr $email
            }
        }

	
        acs_mail_lite::send_immediately \
            -to_addr $to_addr \
            -cc_addr $cc_addr \
            -from_addr "$from_addr" \
            -subject "$subject" \
            -body "$content_body" \
            -package_id $package_id \
            -file_ids $file_ids \
            -mime_type $mime_type \
            -object_id $object_id 

        util_user_message -html -message "[_ acs-mail-lite.Your_message_was_sent_to]"
        
    } -after_submit {
        ad_returnredirect $return_url
    }

