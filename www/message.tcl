ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {attachment_id:integer,multiple,optional}
    {object_id:integer,multiple,optional}
    {party_id:multiple,optional}
    {party_ids ""}
    {search_id:integer ""}
    {message_type ""}
    {message:optional}
    {header_id:integer ""}
    {footer_id:integer ""}
    {return_url "./"}
    {file_ids ""}
    {files_extend:integer,multiple,optional ""}
    {item_id:integer ""}
    {folder_id:integer ""}
    {signature_id:integer ""}
    {subject ""}
    {content_body:html ""}
    {to:integer,multiple,optional ""}
    {page:optional 1}
    {context_id:integer ""}
    {cc ""}
    {bcc ""}
} -validate {
    valid_message_type -requires {message_type} {
	if { ![db_0or1row check_for_it { select 1 from contact_message_types where message_type = :message_type and message_type not in ('header','footer') }] } {
	    ad_complain "[_ intranet-contacts.lt_Your_provided_an_inva]"
	}
    }
}

if { [exists_and_not_null message] && ![exists_and_not_null message_type] } {
    set message_type [lindex [split $message "."] 0]
    set item_id [lindex [split $message "."] 1]
}

if {[empty_string_p $party_ids]} {
    set party_ids [list]
}

set invalid_party_ids  [list]

set package_id [ad_conn package_id]
set recipients  [list]

set recipients_label [_ intranet-contacts.Recipients]
if { $search_id ne "" } {

    set return_url [export_vars -base [apm_package_url_from_id $package_id] -url {search_id}]
    if {[contact::group::mapped_p -group_id $search_id]} {
	# Make sure the user has write permission on the group
	permission::require_permission -object_id $search_id -privilege "write"
	lappend recipients "<a href=\"$return_url\">[contact::group::name -group_id $search_id]</a>"
	if { [contact::group::notifications_p -group_id $search_id] } {
	    set recipients_label [_ intranet-contacts.Notify]
	}
    } else {
	lappend recipients "<a href=\"$return_url\">[contact::search::title -search_id $search_id]</a>"
    }

    # We do the check in the search template
    set valid_party_ids "0"
} else {
    set valid_party_ids ""
    if { [exists_and_not_null party_id] } {
	    foreach p_id $party_id {
	        if {[lsearch $party_ids $p_id] < 0} {
		        lappend party_ids $p_id
	        }
	    }
    } 
    
    # Deal with object_ids passed in
    if { [exists_and_not_null object_id] } {
	    foreach p_id $object_id {
	        if {[lsearch $party_ids $p_id] < 0} {
		        lappend party_ids $p_id
	        }
	    }
    }
    
    if { [exists_and_not_null to] } {
	    foreach party_id $to {
	        lappend party_ids $party_id
	    }
    }
    
    
    # Make sure the parties are visible to the user
    foreach id $party_ids {
        ds_comment "PARTY: $party_ids"
	    if {[contact::visible_p -party_id $id -package_id $package_id]} {
	        lappend valid_party_ids $id
	    }
    }
}

set party_count [llength $valid_party_ids]
set title "[_ intranet-contacts.Messages]"
set user_id [ad_conn user_id]
set context [list $title]

if {![exists_and_not_null valid_party_ids]} {
    ad_return_error "[_ intranet-contacts.No_valid_parties]" "[_ intranet-contacts.No_valid_parties_lt]"
    ad_script_abort
}

set invalid_recipients [list]
set party_ids          [list]

# Make sure that we can actually send the message
foreach party_id $valid_party_ids {
    if { [lsearch [list "letter" "label" "envelope"] $message_type] >= 0 } {

	# Check if we can send a letter to this party
	set letter_p  [contact::message::mailing_address_exists_p -party_id $party_id]
        if { $letter_p } {
            lappend party_ids $party_id
        } else {
            lappend invalid_party_ids $party_id
        }

    } elseif { $message_type == "email" } {
	
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

    } else {
	# We are unsure what to send, so just assume for the time being we can send it to them
	lappend party_ids $party_id
    }
}

# If we are passing in a group, do not show the individual users
if { [empty_string_p $search_id] } {

    # Prepare the recipients
    foreach party_id $party_ids {
	set contact_name   [contact::name -party_id $party_id]
	set contact_url    [contact::url -party_id $party_id]
	lappend recipients   "<a href=\"${contact_url}\">${contact_name}</a>"
    }
    set form_elements "party_ids:text(hidden)"
} else {
    set form_elements ""
}

# Deal with the invalid recipients
foreach party_id $invalid_party_ids {
    set contact_name   [contact::name -party_id $party_id]
    set contact_url    [contact::url -party_id $party_id]
    lappend invalid_recipients   "<a href=\"${contact_url}\">${contact_name}</a>"
}

set recipients [join $recipients ", "]
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

if {[exists_and_not_null attachment_id]} {
    foreach object $attachment_id {
	if {[fs::folder_p -object_id $object]} {
	    db_foreach files {select r.revision_id	
		from cr_revisions r, cr_items i	
		where r.item_id = i.item_id and i.parent_id = :object} {
		    lappend file_list $revision_id
		}
	} else {
	    set revision_id [content::item::get_best_revision -item_id $object]
	    if {[empty_string_p $revision_id]} {
		# so already is a revision
		lappend file_list $object
	    } else {
		# append revision of content item
		lappend file_list $revision_id
	    }
	}
    }
    # If we have files we need to unset the attachment_id
    set attachment_id ""
} else {
    set attachment_id ""
}

if {[exists_and_not_null file_list]} {
    set file_ids [join $file_list " "]
}

append form_elements {
    file_ids:text(hidden)
    search_id:text(hidden)
    return_url:text(hidden)
    folder_id:text(hidden)
    attachment_id:text(hidden)
    context_id:text(hidden)
    {to_name:text(inform),optional {label "$recipients_label"} {value $recipients}}
}

if { ![exists_and_not_null message_type] } {

    set public_text [_ intranet-contacts.Public]
    set package_id [ad_conn package_id]

    set message_type_options [ams::util::localize_and_sort_list_of_lists \
				  -list [db_list_of_lists get_message_types { select pretty_name, message_type from contact_message_types }] \
				 ]
    foreach op $message_type_options {
	set [lindex ${op} 1]_options [list]
	set [lindex ${op} 1]_text [lindex ${op} 0]
    }

    db_foreach get_messages {
	select CASE WHEN owner_id = :package_id THEN :public_text ELSE contact__name(owner_id) END as public_display,
	title,
	to_char(item_id,'FM9999999999999999999999') as item_id,
	message_type
	from contact_messages
	where owner_id in ( select party_id from parties )
	or owner_id = :package_id
	order by CASE WHEN owner_id = :package_id THEN '000000000' ELSE upper(contact__name(owner_id)) END, message_type, upper(title)
    } {
        # The oo_mailing message type is used if you have a mailing template as defined in /lib/oo_mailing
	if {$message_type == "letter" || $message_type == "email" || $message_type == "oo_mailing"} {
	    lappend ${message_type}_options [list "$public_display [set ${message_type}_text]:$title" "${message_type}.$item_id"]
	} else {
	    lappend ${message_type}_options [list "$public_display:$title" "$item_id"]
	}
    }




    # Only Email can be used without a template
    set message_options [list [list "-- [_ intranet-contacts.New] Email --" email]]

    foreach op $message_type_options {
	if { [lsearch [list "header" "footer"] [lindex $op 1]] < 0 } {
	    set message_options [concat $message_options [set [lindex $op 1]_options]]
	}
    }

    if {[exists_and_not_null header_options]} {
	lappend form_elements [list \
			       header_id:text(select) \
			       [list label "[_ intranet-contacts.Header]"] \
			       [list options $header_options] \
			      ]
    }

    if { [llength $message_options] == 1 } {
	lappend form_elements [list message:text(hidden) [list value "email"]]
	set message_type "email"
    } else {
	lappend form_elements [list \
				   message:text(select) \
				   [list label "[_ intranet-contacts.Message]"] \
				   [list options $message_options] \
				  ]
	set message_type ""
    }
    set title [_ intranet-contacts.create_a_message]
    set message_create_p 0
} else {
    set message_create_p 1
}

set context [list $title]

set signature_options_p 0
if { [string is false [exists_and_not_null message]] } {
    set signature_list [list]
    set reset_title $title
    set reset_signature_id $signature_id
    db_foreach signatures "select title, signature_id, default_p
      from contact_signatures
     where party_id = :user_id
     order by default_p, upper(title), upper(signature)" {
         lappend signature_list [list $title $signature_id]
         if { $default_p == "t" } {
             set default_signature_id $signature_id
         }
     }
    set title $reset_title
    set signature_id $reset_signature_id
    if { [llength $signature_list] > 1 } {
	append form_elements {
	    {signature_id:text(select) 
		{label "[_ intranet-contacts.Signature]"}
		{options {$signature_list}}
		
	    }
	}
	set signature_options_p 1
    } elseif { [llength $signature_list] >= 1 } {
	set signature_id [lindex [lindex $signature_list 0] 1]
	set signature_label [lindex [lindex $signature_list 0] 0]
	append form_elements {
	    {signature_pretty:text(inform) 
		{label "[_ intranet-contacts.Signature]"}
		{value {<a href="[export_vars -base "signature" -url {signature_id}]">$signature_label</a>}}
	    }
	    {signature_id:text(hidden) 
		{value {$signature_id}}
	    }
	}
    }
    set signature_id $reset_signature_id
}

if {[exists_and_not_null footer_options]} {
    lappend form_elements [list \
			       footer_id:text(select) \
			       [list label "[_ intranet-contacts.Footer]"] \
			       [list options $footer_options] \
			      ]
}


if { ![exists_and_not_null header_options] && \
	 ![exists_and_not_null footer_options] && \
	 [string is false $signature_options_p] && \
	 $message_type eq "email" } {
    # there is nothing for them to select so we select next for them
    set message_create_p 1
}

if { $message_create_p } {
    set title [_ intranet-contacts.create_$message_type]

    if {$search_id ne ""} {
	# Get the search template
	set message_src "/packages/intranet-contacts/lib/${message_type}-search"
    } else {
	set message_src "/packages/intranet-contacts/lib/${message_type}"
    }
}


set edit_buttons [list [list "[_ intranet-contacts.Next]" create]]

# the message form will reset party_ids so we need to carry it over
set new_party_ids $party_ids
ad_form -action message \
    -name message \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
        if { [exists_and_not_null default_signature_id] } {
            set signature_id $default_signature_id
        } else {
            set signature_id ""
        }
    } -new_request {
    } -edit_request {
    } -on_submit {
    }
set party_ids $new_party_ids

if {[exists_and_not_null signature_id]} {
    set signature [contact::signature::get -signature_id $signature_id]
} else {
    set signature ""
}

