ad_library {

    Support procs for the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
}

namespace eval contact:: {}
namespace eval contact::message:: {}
namespace eval contact::signature:: {}

ad_proc -public contact::signature::get {
    {-signature_id:required}
} {
    Get a signature
} {
    return [template::util::richtext::get_property content [db_string get_signature "select signature from contact_signatures where signature_id = :signature_id" -default {}]]
}

ad_proc -public contact::message::get {
    {-item_id:required}
    {-array:required}
} {
    Get the info on a contact message
} {
    upvar 1 $array row
    db_1row select_message_info { select * from contact_messages where item_id = :item_id } -column_array row
}

ad_proc -private contact::message::save {
    {-item_id:required}
    {-owner_id:required}
    {-message_type:required}
    {-title:required}
    {-description ""}
    {-content:required}
    {-content_format "text/plain"}
    {-locale ""}
    {-banner ""}
    {-ps ""}
    {-oo_template ""}
    {-package_id ""}
} {
    save a contact message
} {
    if { ![db_0or1row item_exists_p { select '1' from contact_message_items where item_id = :item_id }] } {
	if { [db_0or1row item_exists_p { select '1' from acs_objects where object_id = :item_id }] } {
	    error "The item_id specified is not a contact_message_item but already exists as an acs_object. This is not a valid item_id."
	}
        if { ![exists_and_not_null package_id] } {
	    set package_id [ad_conn package_id]
	}

	# we need to create the content item
	content::item::new \
            -name "message.${item_id}" \
            -parent_id [apm_package_id_from_key intranet-contacts] \
	    -item_id $item_id \
	    -creation_user [ad_conn user_id] \
	    -creation_ip [ad_conn peeraddr] \
	    -content_type "content_revision" \
	    -storage_type "text" \
            -package_id $package_id

	db_dml insert_into_message_items {
	    insert into contact_message_items
	    ( item_id, owner_id, message_type, locale, banner, ps, oo_template )
	    values
	    ( :item_id, :owner_id, :message_type, :locale, :banner, :ps, :oo_template )
	}
        # contact item new does not set the package_id in acs_object so
        # we do it here
        db_dml update_package_id {
	    update acs_objects
               set package_id = :package_id
             where object_id = :item_id
	}

    } else {
	db_dml update_message_item {
	    update contact_message_items set owner_id = :owner_id, message_type = :message_type, locale = :locale, banner = :banner, ps = :ps, oo_template = :oo_template where item_id = :item_id
	}
    }

    set revision_id [content::revision::new \
			 -item_id $item_id \
			 -title $title \
			 -description $description \
			 -content $content \
			 -mime_type $content_format \
			 -is_live "t"]

    return $revision_id
}



ad_proc -private contact::message::log {
    {-message_type:required}
    {-sender_id ""}
    {-recipient_id:required}
    {-sent_date ""}
    {-title ""}
    {-description ""}
    {-content:required}
    {-content_format "text/plain"}
    {-item_id ""}
} {
    Logs a message into contact_message_log table.

    @param message_type  The message_type of this message (e.g email, letter).
    @param sender_id     The party_id of the sender of the message.
    @recipient_id        The party_id of the reciever of the message.
    @sent_date           The date when the message was sent. Default to now.
    @title               The title of the logged message.
    @description         The description of the logged message.
    @content             The content of the message.
    @content_format      The format of the content.
    @item_id             The item_id of the message from the default messages.
    
} {
    if { ![exists_and_not_null sender_id] } {
	set sender_id [ad_conn user_id]
    }
    if { ![exists_and_not_null sent_date] } {
	set sent_date [db_string get_current_timestamp { select now() }]
    }
    set creation_ip [ad_conn peeraddr]
    set package_id [ad_conn package_id]

    # First we check the parameter to see if the emails are going to be logged or not,
    # if they are then we check if the message is a default one (message_id).

    if { ![string equal $message_type "email"] } {

	# We make every message logged in this table an acs_object
	set object_id [db_string create_acs_object { }]
	db_dml log_message { }
	
    } elseif { [parameter::get -parameter "LogEmailsP"] && [exists_and_not_null item_id] } {
	
	# We log all emails that used a default email message.
	set object_id [db_string create_acs_object { }]
	db_dml log_message { }
	
    }
}

ad_proc -private contact::message::email_address_exists_p {
    {-party_id:required}
    {-package_id ""}
    {-override_privacy_p "f"}
} {
    Does a message email address exist for this party or his/her employer. Cached via contact::message::email_address.
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [string is false [empty_string_p [contact::message::email_address -party_id $party_id -package_id $package_id -override_privacy_p $override_privacy_p]]]
}

ad_proc -private contact::message::email_address {
    {-party_id:required}
    {-package_id ""}
    {-override_privacy_p "f"}
} {
    Does a message email address exist for this party

    @param override_privacy_p override the privacy contacts settings to force the information to be returned if it exists
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::message::email_address_not_cached -party_id $party_id -package_id $package_id -override_privacy_p $override_privacy_p]]
}

ad_proc -private contact::message::email_address_not_cached {
    {-party_id:required}
    {-package_id:required}
    {-override_privacy_p:required}
} {
    Does a message email address exist for this party

} {
    if { [string is false $override_privacy_p] } {
	if { [contact::privacy_prevents_p -party_id $party_id -package_id $package_id -type "email"] } {
	    return {}
	}
    }
    set email [contact::email -party_id $party_id]
    if { $email eq "" && [contact::type -party_id $party_id] eq "person"} {
	# if this person is the employee of
        # an organization we can attempt to use
        # that organizations email address
#	foreach employer [contact::util::get_employers -employee_id $party_id -package_id $package_id] {
#	    set email [contact::email -party_id [lindex $employer 0]]
#	    if { $email ne "" } {
#		break
#	    }
#	}
    }
    return $email
}

ad_proc -private contact::message::mailing_address_exists_p {
    {-party_id:required}
    {-package_id ""}
    {-override_privacy_p "f"}
} {
    Does a mailing address exist for this party. Cached via contact::message::mailing_address.
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    # since this check is almost always called by a page which
    # will later ask for the mailing address we take on the 
    # overhead of calling for the address, which is cached.
    # this simplifies the code and thus "pre" caches the address
    # for the user, which overall is faster

    return [string is false [empty_string_p [contact::message::mailing_address -party_id $party_id -format "text" -package_id $package_id -override_privacy_p $override_privacy_p]]]
}

ad_proc -private contact::message::mailing_address {
    {-party_id:required}
    {-format "text/plain"}
    {-package_id ""}
    {-override_privacy_p "f"}
    {-with_name:boolean}
} {
    Returns a parties mailing address. Cached

    @param override_privacy_p override the privacy contacts settings to force the information to be returned if it exists

} {
    regsub -all "text/" $format "" format
    if { $format != "html" } {
	set format "text"
    }
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::message::mailing_address_not_cached -party_id $party_id -format $format -package_id $package_id -override_privacy_p $override_privacy_p -with_name_p $with_name_p]]
}

ad_proc -private contact::message::mailing_address_not_cached {
    {-party_id:required}
    {-format:required}
    {-package_id:required}
    {-override_privacy_p:required}
    {-with_name_p:required}
} {
    Returns a parties mailing address
} {
    if { [string is false $override_privacy_p] } {
	if { [contact::privacy_prevents_p -party_id $party_id -package_id $package_id -type "mail"] } {
	    return {}
	}
    }
    set attribute_ids [contact::message::mailing_address_attribute_id_priority -package_id $package_id]
    set revision_id [contact::live_revision -party_id $party_id]
    set mailing_address {}
    foreach attribute_id $attribute_ids {
	append mailing_address [ams::value \
				 -object_id $revision_id \
				 -attribute_id $attribute_id \
				 -format $format]
	if { $mailing_address ne "" } {
	    if {$with_name_p} {
		if {[person::person_p -party_id $party_id]} {
		    set mailing_address "- [contact::name -party_id $party_id] -\n$mailing_address"
		} else {
		    set name "[contact::name -party_id $party_id] \n [ams::value -object_id $revision_id -attribute_name company_name_ext -format $format]"
		    set mailing_address "$name \n$mailing_address"
		}
	    }
	    break
	}
    }
    if { $mailing_address eq "" } {
	# if this person is the employee of
        # an organization we can attempt to use
        # that organizations address
	foreach employer [contact::util::get_employers -employee_id $party_id -package_id $package_id] {
	    append mailing_address [contact::message::mailing_address -party_id [lindex $employer 0] -package_id $package_id -override_privacy_p $override_privacy_p]
	    if { $mailing_address ne "" } {
		# We should display the company name. Currently handled outside this.
		if {$with_name_p} {
		    set employer_id [lindex $employer 0]
		    set employer_rev_id [contact::live_revision -party_id $employer_id]
		    set name "[contact::name -party_id $employer_id]\n[ams::value -object_id $employer_rev_id -attribute_name company_name_ext -format $format]"
		    set mailing_address "$name\n- [contact::name -party_id $party_id] -\n$mailing_address"
		}
		break
	    }
	}
    }
    return $mailing_address
}



ad_proc -private contact::message::mailing_address_attribute_id_priority {
    {-package_id:required}
} {
    Returns the order of priority of attribute_ids for the letter mailing address. Cached
} {
    return [util_memoize [list ::contact::message::mailing_address_attribute_id_priority_not_cached -package_id $package_id]]
}

ad_proc -private contact::message::mailing_address_attribute_id_priority_not_cached {
    {-package_id:required}
} {
    Returns the order of priority of attribute_ids for the letter mailing address
} {
    set attribute_ids [parameter::get -package_id $package_id -parameter "MailingAddressAttributeIdOrder" -default {}]
    if { [llength $attribute_ids] == 0 } {
        # no attribute_id preference was specified so we get all postal_address attribute types and order them
        set postal_address_attributes [db_list_of_lists get_postal_address_attributes { select pretty_name, attribute_id from ams_attributes where widget = 'postal_address'}]
        set postal_address_attributes [ams::util::localize_and_sort_list_of_lists -list $postal_address_attributes]
        set attribute_ids [list]
        foreach attribute $postal_address_attributes {
            lappend attribute_ids [lindex $attribute 1]
        }
    }
    return $attribute_ids
}



ad_proc -private contact::message::interpolate {
    {-values:required}
    {-text:required}
} {
    Interpolates a set of values into a string. This is directly copied from the bulk mail package

    @param values a list of key, value pairs, each one consisting of a
    target string and the value it is to be replaced with.
    @param text the string that is to be interpolated

    @return the interpolated string
} {
    foreach pair $values {
        regsub -all [lindex $pair 0] $text [lindex $pair 1] text
    }
    return $text
}

