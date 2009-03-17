ad_library {

    Support procs for the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
}

namespace eval contacts:: {}
namespace eval contact:: {}
namespace eval contact::util:: {}
namespace eval contact::group:: {}
namespace eval contact::revision:: {}
namespace eval contact::rels:: {}
namespace eval contacts::person:: {}
namespace eval contact::special_attributes {}
namespace eval contacts::group::notification {}
namespace eval ::im {}
namespace eval ::im::contacts {}

ad_proc -public contacts::group::notification::get_url {
    object_id
} {    
    # there is not good page to send users regarding a group
    # so we don't bring them anywhere
    return "/notifications/manage"
}

ad_proc -public contacts::group::notification::process_reply {
    reply_id
} {

}



ad_proc -public contacts::default_group {
    {-package_id ""}
} {
    Returns the default group_id a contacts instance. Cached.
} {
    if {[string is false [exists_and_not_null package_id]]} {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list contacts::default_group_not_cached -package_id $package_id]]
}

ad_proc -private contacts::default_group_not_cached {
    {-package_id:required}
} {
    Returns the default group_id a contacts instance.
} {
    if { [string is true [parameter::get -package_id $package_id -parameter "UseSubsiteAsDefaultGroup" -default "0"]] } {
	# we cannot trust ad_conn subsite_id because instances may be asking for subsites of numerous other packages.
        set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
        set package_id [site_node::closest_ancestor_package -node_id $node_id -package_key "acs-subsite"]
    }

    set group_id [application_group::group_id_from_package_id -no_complain -package_id $package_id]
    if {[string eq "" $group_id]} {
        # application_group should not be empty unless contacts
	set group_id "-2"
    }
    return $group_id
}


ad_proc -public contacts::default_groups {
    {-package_id ""}
} {
    Returns a list of group_ids that this instance searches for. Cached.
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list contacts::default_groups_not_cached -package_id $package_id]]
}

ad_proc -private contacts::default_groups_not_cached {
    {-package_id:required}
} {
    Returns a list of group_ids that this instance searches for.
} {
    if { [parameter::get -package_id $package_id -parameter "IncludeChildPackages" -default "0"] } {
        set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
       set parent_node_id [site_node::get_parent_id -node_id $node_id]
        # this search currently does not differentiate between child
        # instances mounted on subsites or on other packages. Don't
        # know if this is good or bad... matthewg
	set package_ids [db_list get_child_contacts_instances {}]
	set package_ids [concat $package_id $package_ids]
	set group_ids [list]
	foreach package_id $package_ids {
	    lappend group_ids [contacts::default_group -package_id $package_id]
	}
	return [lsort -unique $group_ids]
    } else {
	return [contacts::default_group -package_id $package_id]
    }
}

ad_proc -public contact::package_id {
    -party_id:required
} {
    Return the contacts package_id of a party
} {
    return [apm_package_id_from_key "intranet-contacts"]
}
	
ad_proc -private contacts::sweeper {
    {-contacts_package_ids ""}
} {
    So that contacts searches work correctly, and quickly
    every person or organization in the system
    needs an associated content_item and live revision
    this could be done with left joins on persons and organizations
    tables but its slower so we create the necessary item_ids
    for person or organization objects that were not created
    by contacts (ones created by contacts automatically get
    associated item_id and live_revisions.
} {

    # Make sure that only one thread is processing the queue at a
    # time.
    if {[nsv_incr contacts sweeper_p] > 1} {
	nsv_incr contacts sweeper_p -1
	return
    }

    with_finally -code {
	if {$contacts_package_ids eq ""} {
	    set contacts_package_ids [apm_package_ids_from_key -package_key "contacts" -mounted]
	}
	
	if {$contacts_package_ids eq ""} {
	    # there is no contacts package mounted, so do not bother
	    return
	}

	set default_groups [list]
	foreach contact_package_id $contacts_package_ids {
	    set default_group_id [contacts::default_group -package_id $contact_package_id]
	    set contact_package($default_group_id) $contact_package_id
	    lappend default_groups $default_group_id
	}
	
	# Count number of persons without items
	set person_num [db_string get_persons_num {}]
	set counter 0
	
	# Try to insert the persons into the package_id of the first group found
	db_foreach get_persons_without_items {} {

	    foreach group_id $default_groups {
		if {[group::party_member_p -party_id $person_id -group_id $group_id]} {
		    set contact_revision_id [contact::revision::new -party_id $person_id -package_id $contact_package($group_id)]
                        break
		}
	    }	    

	    if {![exists_and_not_null contact_revision_id]} {
		# We did not found a group, so just use the first contacts instance.
		if {[ad_conn isconnected]} {
		    set user_id [ad_conn user_id]
		    set peeraddr [ad_conn peeraddr]
		} else {
		    set user_id $person_id
		    set peeraddr 127.0.0.1
		}
		set contact_revision_id [contact::revision::new -party_id $person_id -package_id $contact_package_id -creation_user $user_id -creation_ip $peeraddr]
	    }
	    
	    # Add the default ams attributes
	    foreach attribute {first_names last_name email} {
		if {[exists_and_not_null $attribute]} {
		    ams::attribute::save::text -object_type "person" -object_id $contact_revision_id -attribute_name "$attribute" -value [set $attribute]
		}
	    }
	    
	    incr counter
	    ns_log notice "contacts::sweeper ($counter / $person_num) creating content_item and content_revision $contact_revision_id for party_id: $person_id"
	}
	
	db_foreach get_organizations_without_items {} {
	    foreach group_id $default_groups {
		if {[group::party_member_p -party_id $organization_id -group_id $group_id]} {
		    contact::revision::new -party_id $organization_id -package_id $contact_package($group_id) -creation_user 0
		    break
		}
	    }
	    ns_log notice "contacts::sweeper creating content_item and content_revision for organization_id: $organization_id"
	    contact::revision::new -party_id $organization_id -package_id $contact_package_id
	}
	
	if { ![info exists person_id] && ![info exists organization_id] } {
	    ns_log Debug "contacts::create_revisions_sweeper no person or organization objects exist that do not have associated content_items"
	}
	db_dml insert_privacy_records {}
	# Delete records where the user_id has been deleted. After all, deleted users should not show up in contacts either
	foreach group_id $default_groups {
	    db_dml delete_deleted_users {}
	}
	
    } -finally {
	nsv_incr contacts sweeper_p -1
    }
    
}
    
ad_proc -public contacts::multirow {
    {-extend ""}
    {-multirow}
    {-select_query}
    {-party_id_column "object_id"}
    {-format "html"}
} {
    This procedure extends a contacts multirow by the type.key pairs specified as 
    a list as the extend param. The supplied select query will return a list of
    party_ids to the callback proc... this proc is then to use the subselct
    in their retrieval of the values requested. A list of lists, i.e.
    {{party_id1 value1} {party_id2 value2}}
    this procedure then takes that list of lists and matches values with parties
    and extends the multirow provided with those values
} {
    if { $format ne "text" } {
	    set format "html"
    }
    foreach id $extend {
	    set ${id}__list ""
	    regexp {^(.*?).(.*)$} $id match type key
	    
	    set results [callback contacts::multirow::extend -type $type -key $key -select_query $select_query -format $format]
	    foreach result $results {
	        if { $result ne "" } {
		        array set "${id}__array" $result
	        }
	    }
	    template::multirow extend $multirow $id
    }
    template::multirow foreach $multirow {
	    foreach id $extend {
	        if { [info exists ${id}__array([set ${party_id_column}])] } {
		        set $id [set ${id}__array([set ${party_id_column}])]
	        }
	    }
    }
}

ad_proc -public contact::privacy_prevents_p {
    {-party_id:required}
    {-type:required}
    {-package_id ""}
} {
    @param party_id the party_id to check permission for
    @param type either 'email', 'mail' or 'phone'
    @returns 1 or 0 if the specified type of communication is allowed
} {
    # ToDo: Enable permissions!
    return 0
    if { [contact::privacy_allows_p -party_id $party_id -type $type -package_id $package_id] } {
	return 0
    } else {
	return 1
    }
}

ad_proc -public contact::privacy_set {
    {-party_id:required}
    {-email_p:required}
    {-mail_p:required}
    {-phone_p:required}
    {-gone_p:required}
} {
} {
    db_transaction {
	if { [db_0or1row record_exists_p {}] } {
	    db_dml update_privacy {}
	} else {
	    db_dml insert_privacy {}
	}
    }
}

ad_proc -public contact::util::get_account_manager {
    {-organization_id:required}
} {
    get the account manager's party_id for an organization
} {
    return [db_list account_id "select object_id_one from acs_rels where rel_type='contact_rels_am' and object_id_two = :organization_id"]
}

ad_proc -private contact::util::generate_filename {
    {-title:required}
    {-extension:required}
    {-existing_filenames ""}
    {-party_id ""}
} {
    Generate a pretty filename that relates to the title supplied

    @param party_id if supplied the filenames associated with this party will be used as existing_filenames if existing filenames is not provided

    @param existing_filenames a list of filenames that the generated filename must not be equal to
} {
    if {[exists_and_not_null party_id] 
	&& [string is integer $party_id] && ![exists_and_not_null existing_filenames]} {
	set existing_filenames [db_list get_parties_existing_filenames {}]
    }
    set filename [util_text_to_url \
		      -text ${title} -replacement "_"]
    set output_filename "${filename}.${extension}"
    set num 1
    while {[lsearch $existing_filenames $output_filename] >= 0} {
	set output_filename "${filename}${num}.${extension}"
	incr num
    }
    return $output_filename
}

ad_proc -private contact::util::get_file_extension {
    {-filename:required}
} {
    get the file extension from a file
} {
    return [lindex [split $filename "."] end]
}

ad_proc -private contact::util::update_person_attributes {
} {
    Updates the person attributes first_names, last_name, email for people who have not been entered using contacts
} {
    db_foreach persons {select latest_revision as object_id, first_names, last_name, email from persons, parties,cr_items where person_id = party_id and person_id = item_id} {
	ams::attribute::save::text -object_id $object_id -attribute_name "first_names" -value "$first_names" -object_type "person"
	ams::attribute::save::text -object_id $object_id -attribute_name "last_name"  -value "$last_name" -object_type "person"
	ams::attribute::save::text -object_id $object_id -attribute_name "email" -value "$email" -object_type "person"
    }
}


ad_proc -public contact::util::get_account_manager {
    {-organization_id:required}
} {
    get the account manager's party_id for an organization
} {
    return [db_list account_id "select object_id_one from acs_rels where rel_type='contact_rels_am' and object_id_two = :organization_id"]
}




ad_proc -public contact::salutation {
    {-party_id:required}
    {-type salutation}
} {
    Get salutation string.

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-12-12
    @param party_id The ID of the party whose information you wish to retrieve.
    @param type either salutation or letter

    @return salutation / sticker salutation string.
} {
    return [util_memoize [list ::contact::salutation_not_cached -party_id $party_id -type $type]]
}

ad_proc -private contact::salutation_not_cached {
    {-party_id:required}
    {-type salutation}
} {
    Get salutation string.

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-12-12
    @param party_id The ID of the party whose information you wish to retrieve.
    @param type either salutation or letter

    @return salutation / sticker salutation string.
} {
    # Check if ID belongs to a person
    if {![person::person_p -party_id $party_id]} {
	if {$type == "salutation"} {
	    # standard salutation
	    return "Sehr geehrte Damen und Herren"
	} else {
	    # empty sticker salutation for organizations
	    return
	}
    }

    set locale [lang::user::site_wide_locale -user_id $party_id]
    set revision_id [content::item::get_best_revision -item_id $party_id]
    foreach attribute [list "first_names" "last_name" "salutation" "person_title"] {
	set value($attribute) [string trim [ams::value -object_id $revision_id -attribute_name $attribute -locale $locale]]
    }

    if {$type == "salutation"} {
	# long salutation (though still without the first name)
	# Check for informal salutation
	if {$value(salutation) eq "Hello" || $value(salutation) eq "Hallo"} {
	    return "$value(salutation) [string trim "$value(first_names)"]"
	} else {
	    return "$value(salutation) [string trim "$value(person_title) $value(last_name)"]"
	}
    } else {
	# short sticker salutation
	set name [string trim "$value(first_names) $value(last_name)"]
	return "- [string trim "$value(person_title) $name"] -"
    }
}


ad_proc -private contact::flush {
    {-party_id:required}
} {
    Flush memorized information related to this contact
} {
    util_memoize_flush "acs_object_type $party_id"
    util_memoize_flush_regexp "contact(.*?)${party_id}"
    # in order to flush person::name and any other
    # procs that may show up there we also flush person
    # procs for this party_id
    util_memoize_flush_regexp "person(.*?)${party_id}"
}

ad_proc -public contact::name {
    {-party_id:required}
    {-reverse_order:boolean}
} {
    this returns the contact's name. Cached
} {
    return [util_memoize [list ::contact::name_not_cached -party_id $party_id -reverse_order_p $reverse_order_p]]
}

ad_proc -public contact::name_not_cached {
    {-party_id:required}
    {-reverse_order_p:required}
} {
    this returns the contact's name
} {
    set object_type [acs_object_type $party_id]
    switch $object_type {
	person {
	    if {$reverse_order_p} {
		set person_info [db_string get_person_name {select last_name || ', ' || first_names from persons where person_id = :party_id} -default ""]
	    } else {
		set person_info [person::name -person_id $party_id]
	    }
	} 
	user {
	    if {$reverse_order_p} {
		set person_info [db_string get_person_name {select last_name || ', ' || first_names from persons where person_id = :party_id} -default ""]
	    } else {
		set person_info [person::name -person_id $party_id]
	    }
	} 
	im_company {
	    return [::xo::db::sql::im_company name -company_id $party_id]
	} 
	im_office {
	    return [::xo::db::sql::im_office name -office_id $party_id]
	} 
	group {
	    return name [db_string get_group_name {select group_name from groups where group_id = :party_id} -default {}]
	} 
	default {
	    return [acs_object_name $party_id]
	}
    }
}

ad_proc -public contact::email {
    {-party_id:required}
} {
    this returns the contact's name. Cached
} {
    return [util_memoize [list ::contact::email_not_cached -party_id $party_id]]
}

ad_proc -public contact::email_not_cached {
    {-party_id:required}
} {
    this returns the contact's name
} {
    # we should use party::email here but 
    # we need to wait for the new version of
    # acs-subsite to be release to remove
    # the dependence on contacts which
    # would cause an infinit loop
    set email [cc_email_from_party $party_id]
    if { ![exists_and_not_null email] } {
	# we check if there is an attribute_valued email address for this party
	set attribute_id [attribute::id -object_type "party" -attribute_name "email"]
	set revision_id [contact::live_revision -party_id $party_id]
	if { [exists_and_not_null revision_id] } {
	    set email [ams::value -object_id $revision_id -attribute_id $attribute_id]
	}
    }
    return $email
}

ad_proc -public contact::link {
    {-party_id:required}
} {
    this returns the contact's name. Cached
} {
    set contact_name [contact::name -party_id $party_id]
    if { ![empty_string_p $contact_name] } {
        set contact_url [contact::url -party_id $party_id]
        return "<a href=\"${contact_url}\">${contact_name}</a>"
    } else {
        return {}
    }
}

ad_proc -public contact::type {
    {-party_id:required}
} {
    returns the contact type
} {
    set object_type [util_memoize [list acs_object_type $party_id]]
    if { [lsearch [intranet-contacts::supported_object_types] $object_type] >= 0 } {
	return $object_type
    } else {
	return ""
    }
}

ad_proc -public contact::exists_p {
    {-party_id:required}
} {
    does this contact exist?
} {
    # persons can be organizations so we need to do the check this way
    set object_type [acs_object_type $party_id]
    if {$object_type eq "user"} {
        set object_type "person"
    }    
    if { [lsearch [intranet-contacts::supported_object_types] $object_type] >= 0 } {
	    return 1
    } else {
	    return 0
    }
}

ad_proc -public contact::user_p {
    {-party_id:required}
} {
    is this party a user? Cached
} {
    if { [contact::type -party_id $party_id] == "user" } {
	return 1
    } else {
	return 0
    }
}

ad_proc -public contact::require_visiblity {
    {-party_id:required}
    {-package_id ""}
} {
} {
    if { [string is false [contact::visible_p -party_id $party_id -package_id $package_id]] } {
	# we return not found because we cannot sepecify whether or
        # not the contact exists to the user for privacy reasons
        # locations such as hospitals, etc.
	ns_returnnotfound
	ad_script_abort
    }
}

ad_proc -public contact::visible_p {
    {-party_id:required}
    {-package_id ""}
} {
    Is the contact visible to the specified package. Cached.
} {
    if { [string is false [exists_and_not_null package_id]] } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::visible_p_not_cached -party_id $party_id -package_id $package_id]]
}

ad_proc -private contact::visible_p_not_cached {
    {-party_id:required}
    {-package_id:required}
} {
    Is the contact visible to the specified package.
} {
    return 1
    ad_script_abort
    if { [db_0or1row get_contact_visible_p {}] } {
	return 1
    } else {
	return 0
    }
}

ad_proc -public contact::url {
    {-party_id:required}
    {-package_id ""}
} {
    create a contact revision
} {
    set package_id [apm_package_id_from_key "intranet-contacts"]

    return "[apm_package_url_from_id $package_id]${party_id}/"
}

ad_proc -public contact::revision::new {
    {-party_id:required}
    {-party_revision_id ""}
    {-package_id ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    create a contact revision
} {
    if {$package_id eq ""} {
	set package_id [ad_conn package_id]
    }

    set extra_vars [ns_set create]

    if {![db_string item_exists_p "select 1 from cr_items where item_id = :party_id" -default 0]} {
	db_dml insert_item {}
    }
    
    set party_revision_id [content::revision::new -item_id $party_id -package_id $package_id -is_live "t" -creation_user $creation_user -creation_ip $creation_ip ]
    if {![db_string item_exists_p "select 1 from contact_party_revisions where party_revision_id = :party_revision_id" -default 0]} {
	db_dml insert_contact_revision "insert into contact_party_revisions ( party_revision_id ) values ( :party_revision_id )"
    }
    return $party_revision_id
}

ad_proc -public contact::live_revision {
    {-party_id:required}
} {
    create a contact revision
} {
    # since we run the sweeper to create cr_items for every contact
    # we know that it has a cr_item, so we can simply use the item
    # proc.
    #if {[db_0or1row revision_exists_p {select 1 from cr_items where item_id = :party_id}]} {
    #	return [item::get_live_revision $party_id]
    #} else {
    #	return ""
    #}
    return [item::get_live_revision $party_id]
}

ad_proc -public contact::subsite_user_group {
    {-party_id:required}
} {
    create a contact revision
} {
    if {[db_0or1row revision_exists_p {select 1 from cr_items where item_id = :party_id}]} {
	return [item::get_live_revision $party_id]} else {
	    return ""
	}
}

ad_proc -private contact::person_upgrade_to_user {
    {-person_id ""}
    {-no_perm_check "f"}
} {
    Upgrade a person to a user. This proc does not send an email to the newly created user.
} {
    contact::flush -party_id $person_id
    set user_id $person_id
    set username [contact::email -party_id $person_id]
    set authority_id [auth::authority::local]


    # Make sure that we do not upgrade an already existing user
    if {![contact::user_p -party_id $person_id] && [string eq "" [acs_user::get_by_username -username $username]]} {
	db_transaction {
	    db_dml upgrade_user {update acs_objects set object_type = 'user' where object_id = :user_id;
		
		insert into users
		(user_id, authority_id, username, email_verified_p)
		values
		(:user_id, :authority_id, :username, 't');
		
	    }

	    # Make sure that we we did not store user preferences before
	    if {![db_string user_prefs_p "select 1 from user_preferences where user_id = :user_id" -default "0"]} {
		db_dml update_user_prefs {insert into user_preferences
		    (user_id)
		    values
		    (:user_id);
		}
	    }
	    
	    # we reset the password in admin mode. this means that an email
	    # will not automatically be sent.
	    auth::password::reset -authority_id [auth::authority::local] -username $username -admin
	    if { [string is true $no_perm_check] } {
		contact::group::add_member \
		    -no_perm_check \
		    -group_id "-2" \
		    -user_id $person_id \
		    -rel_type "membership_rel"
	    } else {
		contact::group::add_member \
		    -group_id "-2" \
		    -user_id $person_id \
		    -rel_type "membership_rel"
	    }
	    # Grant the user to update the password on himself
	    permission::grant -party_id $user_id -object_id $user_id -privilege write

	    set success_p 1
	} on_error {
	    error "There was an error in contact::person_upgrade_to_user: $errmsg"
	    set success_p 0
	}
	contact::flush -party_id $person_id
	return "$success_p"
    }
}

ad_proc -private contact::group::new {
    {-group_id ""}
    {-email ""}
    {-url ""}
    -group_name:required
    {-join_policy "open"}
    {-context_id:required}
} {
    this creates a new group for use with contacts (and the permissions system)
} {
    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]
    set group_name [lang::util::convert_to_i18n -prefix "group" -text "$group_name"]

    return [db_string create_group {}]
}

ad_proc -public contact::group::map {
    -group_id:required
    {-package_id ""}
    {-default_p "f"}
    {-notifications_p "f"}
} {
    this creates a new group for use with contacts (and the permissions system)
} {
    if {[empty_string_p $package_id]} {
	set package_id [ad_conn package_id]
    }
    db_dml map_group {}
}

ad_proc -public contact::group::mapped_p {
    -group_id:required
    {-package_id ""}
} {
    this creates a new group for use with contacts (and the permissions system)
} {
    if {[empty_string_p $package_id]} {
	set package_id [ad_conn package_id]
    }
    return [db_0or1row select_mapped_p {}]
}

ad_proc -public contact::group::notifications_p {
    -group_id:required
} {
    Does this group use notifications (if one contacts instance does then all do, since the group is not bound to the contacts instance)
} {
    return [db_0or1row select_notifications_p {}]
}

ad_proc -public contact::group::name {
    -group_id:required
} {
    Get the group name for contacts (this might be a dotlrn community name or a group title)
} {
    if {[info procs dotlrn_community::get_community_name] eq ""} {
	set dotlrn_community_name ""
    } else {
	set dotlrn_community_name [dotlrn_community::get_community_name $group_id]
    }
    if { $dotlrn_community_name ne "" } {
	return $dotlrn_community_name
    } else {
	return [lang::util::localize [lang::util::localize [group::title -group_id $group_id]]]
    }
}


ad_proc -public contact::group::add_member {
    {-no_perm_check:boolean}
    {-group_id:required}
    {-user_id:required}
    {-rel_type ""}
    {-member_state ""}
} {
    Adds a user to a group, checking that the rel_type is permissible given the user's privileges,
    Can default both the rel_type and the member_state to their relevant values.
} {
    set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]


    # Only admins can add non-membership_rel members
    if { $rel_type eq "" || \
             (!$no_perm_check_p && $rel_type ne "" && $rel_type ne "membership_rel" && \
                  ![permission::permission_p -object_id $group_id -privilege "admin"]) } {
	switch [contact::type -party_id $user_id] {
	    person - user {
		set rel_type "membership_rel"
	    }
	    organization {
		set rel_type "organization_rel"
	    }
	}
    }

    group::get -group_id $group_id -array group

    if { !$no_perm_check_p } {
        set create_p [group::permission_p -privilege create $group_id]
        if { $group(join_policy) eq "closed" && !$create_p } {
            error "You do not have permission to add members to the group '$group(group_name)'"
        }
    } else {
        set create_p 1
    }

    if { $member_state eq "" } {
        set member_state [group::default_member_state \
                              -join_policy $group(join_policy) \
                              -create_p $create_p]
    }

    if { $rel_type eq "organization_rel" } {
	# They are using the special organization_rel which
        # needs to be added differently since organizations
        # can be part of a group which violates the membership_rel
        # constraint for a group member to be a person see:
        # http://openacs.org/forums/message-view?message_id=1059049
        #
        # The organization_rel behaves exactly like a basic membership_rel
        # and uses the exact same tables, but it allows an organization
        # to be a member of a group. If the constraint is dropped/changed
        # then this code could be cleaned up to act like the other rel
        # types listed below - and potentially all organization_rels can be
        # updated and changed into membership_rels

	set existing_rel_id [db_string rel_exists { 
	    select rel_id
	    from   acs_rels 
	    where  rel_type = :rel_type 
            and    object_id_one = :group_id
            and    object_id_two = :user_id
	} -default {}]
        if { [empty_string_p $existing_rel_id] } {
	    if { [ad_conn isconnected] } {
		set peeraddr [ad_conn peeraddr]
		set creation_user [ad_conn user_id]
	    } else {
		set user_id $organization_id
		set peeraddr 127.0.0.1
	    }
	    set rel_id [db_string insert_rels { select acs_rel__new (NULL::integer,:rel_type,:group_id,:user_id,NULL,:creation_user,:peeraddr) as org_rel_id }]
	    db_dml insert_state { insert into membership_rels (rel_id,member_state) values (:rel_id,:member_state) }
	} else {
            # update member state
            db_dml update_state { update membership_rels set member_state = :member_state where rel_id = :existing_rel_id }
        }
    } else {
	if { $rel_type ne "membership_rel" } {
	    # add them with a membership_rel first
	    relation_add -member_state $member_state "membership_rel" $group_id $user_id
	}
	relation_add -member_state $member_state $rel_type $group_id $user_id
    }    
    group::flush_members_cache -group_id $group_id

    if { [contact::group::notifications_p -group_id $group_id] && [contact::type -party_id $user_id] ne "organization" } {
	if { [contact::type -party_id $user_id] ne "user" } {
	    util_user_message -message "Only users can be notified. The person ($user_id) was added to the group."
	}
	# notifications only allows users to receive notifications.
	# this actually makes sense, since the recipient needs
	# a way to remove themselves from the notifications
	# they are getting.
	#
	# We could potentially automatically upgrade a person
	# to a user user if a notification request is made.
	# to do this uncomment the following
	# contact::person_upgrade_to_user -person_id $user_id -no_perm_check "t"

	

	notification::request::new \
	    -type_id [notification::type::get_type_id -short_name contacts_group_notif] \
	    -user_id $user_id \
	    -object_id $group_id \
	    -interval_id [notification::get_interval_id -name instant] \
	    -delivery_method_id [notification::get_delivery_method_id -name email] \
	    -format "html"
    }

}


ad_proc -public contact::group::parent {
    -group_id:required
} {
    returns the group_id for which this group is a component, if none then it return null
} {
    return [db_string get_parent {} -default {}]
}

ad_proc -public contact::groups_list {
    {-package_id ""}
    {-include_dotlrn_p "0"}
} {
    Retrieve a list of all groups currently in the system
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list contact::groups_list_not_cached -package_id $package_id -include_dotlrn_p $include_dotlrn_p]]
}

ad_proc -public contact::groups_list_not_cached {
    -package_id:required
    -include_dotlrn_p:required
} {
    Retrieve a list of all groups currently in the system
} {
    set name_field "acs_objects.title"
    set dotlrn_community_p " '0'::boolean "
    set additional_from ""
    set additional_where ""
    if { [apm_package_installed_p dotlrn] } {
	set name_field " CASE WHEN dotlrn_communities_all.community_id is not null THEN dotlrn_communities_all.pretty_name ELSE acs_objects.title END "
        set dotlrn_community_p " CASE WHEN dotlrn_communities_all.community_id is not null THEN '1'::boolean ELSE '0'::boolean END " 
	set additional_from " left join dotlrn_communities_all on ( acs_objects.object_id = dotlrn_communities_all.community_id )"
	if { [string is true $include_dotlrn_p] } {
	    # we hid archived, but not active communities
	    set additional_where "and CASE WHEN dotlrn_communities_all.archived_p = 'f' OR dotlrn_communities_all.community_id is null THEN '1'::boolean ELSE 'f'::boolean END"
	} else {
	    set additional_where  "and dotlrn_communities_all.community_id is null"
	}
    }
    return [db_list_of_lists get_groups {}]
}

ad_proc -public contact::groups {
    {-expand "all"}
    {-indent_with "..."}
    {-privilege_required "read"}
    {-output "list"}
    {-all:boolean}
    {-no_member_count:boolean}
    {-package_id ""}
    {-party_id ""}
    {-include_dotlrn_p "0"}
} {
    Return the groups that are mapped in contacts
    
    THIS ONLY WORKS FOR PERSONS CORRECTLY AT THIS POINT IN TIME!
    
    @param indent_with What should we indent the group name with
    @privilege_required Required privilege the user has to have on this group
    @output Format in which to output the groups. A tcl list of lists is standard
    @party_id If the privilege is write we need to check if the user is maybe writing on himself. Then he should have permission.
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }

    set user_id [ad_conn user_id]
    set group_list [list]
    foreach one_group [contact::groups_list -package_id $package_id -include_dotlrn_p $include_dotlrn_p] {
	util_unlist $one_group group_id group_name member_count component_count mapped_p default_p user_change_p dotlrn_community_p
	if {$user_change_p eq ""} {
	    set user_change_p 0
	}
	# We check if the group has the required privilege 
	# specified on privilege_required switch, if not then
	# we just simple continue with the next one
	if { ![permission::permission_p -object_id $group_id -party_id $user_id -privilege $privilege_required] } {
	    if { $privilege_required eq "write" && $user_change_p} {
		# Check if the user is editing himself
		if {![string eq $party_id $user_id]} {
		    continue
		}
	    } else {
		continue
	    }
	}
        if { $mapped_p || $all_p} {
	    # we localize twice because for some reason some localized keys references another localized key
            lappend group_list [list [lang::util::localize [lang::util::localize $group_name]] $group_id $member_count "1" $mapped_p $default_p $user_change_p $dotlrn_community_p]
            if { $component_count > 0 && ( $expand == "all" || $expand == $group_id ) } {
                db_foreach get_components {} {
		    if { $mapped_p || $all_p} {
			lappend group_list [list "$indent_with[lang::util::localize [lang::util::localize $group_name]]" $group_id $member_count "2" $mapped_p $default_p $user_change_p $dotlrn_community_p]
		    }
		}
            }
        }
    }

    switch $output {
        list {
	    ns_log notice "last $group_list"
            set list_output [list]
            foreach group $group_list {
		if {$no_member_count_p} {
		    lappend list_output [list [lindex $group 0] [lindex $group 1]]
		} else {
		    lappend list_output [list [lindex $group 0] [lindex $group 1] [lindex $group 2]]
		}
            }
            return $list_output
        }
        ad_form {
            set ad_form_output [list]
            foreach group $group_list {
                lappend ad_form_output [list [lindex $group 0] [lindex $group 1]]
            }
	    return $ad_form_output
        }
        default {
            return $group_list
        }
    }
}

ad_proc -public contacts::person::new {
    {-first_names:required}
    {-last_name:required}
    {-email:required}
    {-contacts_package_id ""}
} {
    Insert a new person into contacts
    This will add them to the default group and add the ams attributes.
} {

    if {[string eq "" $contacts_package_id]} {
	set contacts_package_id [ad_conn package_id]
    } 

    # Create the new person
    set person_id [person::new -first_names $first_names -last_name $last_name -email $email]

    # Add to default group
    set default_group_id [contacts::default_group -package_id $contacts_package_id]
    contact::group::add_member \
	-group_id $default_group_id \
	-user_id $person_id \
	-rel_type "membership_rel" \
        -no_perm_check

    # Store the AMS attribute
    set object_id [contact::revision::new -party_id $person_id]
    ams::attribute::save::text -object_id $object_id -attribute_name "first_names" -value "$first_names" -object_type "person"
    ams::attribute::save::text -object_id $object_id -attribute_name "last_name"  -value "$last_name" -object_type "person"
    ams::attribute::save::text -object_id $object_id -attribute_name "email" -value "$email" -object_type "person"
    
    return $person_id
}


ad_proc -public contacts::merge {
    {-from_party_id:required}
    {-to_party_id:required}
} {
    Merge two contacts, there is also a contacts::merge callback so that other packages can
    get in on the action of this proc.
} {
    


    set to_type [contact::type -party_id $to_party_id]
    set from_type [contact::type -party_id $from_party_id]

    if { [lsearch [list person user organization] $to_type] < 0 } {
	error "To type is not a contact"
	ad_script_abort
    }
    if { [lsearch [list person user organization] $from_type] < 0 } {
	error "From type is not a contact"
	ad_script_abort
    }

    if { $to_type eq "organization" && $from_type ne "organization" } {
	error "You cannot merge an organization with a person"
	ad_script_abort
    } elseif { $to_type eq "person" && $from_type eq "user" } {
#	error "You cannot merge a user into a person"
#	ad_script_abort
	set original_to_party_id $to_party_id
	set to_party_id $from_party_id
	set from_party_id $original_to_party_id
    }

    ns_log notice "Starting merge to $to_party_id ([contact::name -party_id $to_party_id]) from $from_party_id ([contact::name -party_id $from_party_id])"



    foreach name [ns_cache names util_memoize] {
	ns_cache flush util_memoize $name
    } 


    db_transaction {
	# contact lists
	foreach list_id [db_list get_lists { select list_id from contact_list_members where party_id = :from_party_id }] {
	    contact::list::member_add -list_id $list_id -party_id $to_party_id
	    contact::list::member_delete -list_id $list_id -party_id $from_party_id
	}


	# contact messages
	db_dml update_message_log { update contact_message_log set recipient_id = :to_party_id where recipient_id = :from_party_id }
	

	# AMS Attributes
	
	set revision_id [contact::live_revision -party_id $to_party_id]
	set new_revision_id [contact::revision::new -party_id $to_party_id]
	ams::object_copy -from $revision_id -to $new_revision_id
	
	set merge_revision_id [contact::live_revision -party_id $from_party_id]
	ams::object_copy -from $merge_revision_id -to $new_revision_id
	

	# Generic Attributes
	
	db_dml delete_empty_attribute_values "
	    delete from acs_attribute_values where object_id = :to_party_id and attr_value is null
	"
	

	db_dml update_generic_attributes "

	    insert into acs_attribute_values
	    (object_id,attribute_id,attr_value)
	    ( select :to_party_id,
	             attribute_id,
                     attr_value
                from acs_attribute_values
               where object_id = :from_party_id 
                 and attribute_id not in ( select attribute_id from acs_attribute_values where object_id = :to_party_id and attr_value is not null )
            )

	"

	# we only update email addresses and url if it doesn't exists on the primary party_id
	if { ![db_0or1row get_it " select 1 from parties where party_id = :to_party_id and email is not null "] } {
	    set email [db_string get_info " select email from parties where party_id = :from_party_id " -default {}]
	    if { [exists_and_not_null email] } {
		db_dml update_it " update parties set email = NULL where party_id = :from_party_id "
		db_dml update_it " update parties set email = :email where party_id = :to_party_id "
		if { [contact::type -party_id $to_party_id] == "user" } {
		    # db_dml update_it " update users set username = :from_party_id where user_id = :from_party_id "
		    # db_dml update_it " update users set username = :email where user_id = :to_party_id "
		}
	    }
	}
	if { ![db_0or1row get_it " select 1 from parties where party_id = :to_party_id and url is not null "] } {
	    set url [db_string get_info " select url from parties where party_id = :from_party_id " -default {}]
	    if { [exists_and_not_null url] } {
		db_dml update_it " update parties set url = NULL where party_id = :from_party_id "
		db_dml update_it " update parties set url = :url where party_id = :to_party_id "
	    }
	}


	# files
	db_dml update_it { update cr_items set parent_id = :to_party_id where parent_id = :from_party_id }
	

	# cr_child _rels
	db_dml update_it { update cr_child_rels set parent_id = :to_party_id where parent_id = :from_party_id }



	# Tasks
	if { [apm_package_installed_p tasks] } {
	    db_dml update_it { update pm_task_assignment set party_id = :to_party_id where party_id = :from_party_id }
	}

	# General Comments
	db_dml update_comments { update general_comments set object_id = :to_party_id where object_id = :from_party_id }

	# Forums Messages
	# if contacts becomes ubiquitous enough this should be moved to a callback managed by the forums packages
	if { [apm_package_installed_p forums] } {
	    db_dml update_contexts { update acs_objects set creation_user = :to_party_id where object_id in ( select message_id from forums_messages where user_id = :from_party_id ) }
	    db_dml update_messages { update forums_messages set user_id = :to_party_id where user_id = :from_party_id }
	}

	# Mail Lite
	if { [apm_package_installed_p acs-mail-lite] } {
	    
	    db_dml update_acs_mail_lite_mail_log { update acs_mail_lite_mail_log set party_id = :to_party_id where party_id = :from_party_id }
	    
	}
	
	# Mail Tracking
	if { [apm_package_installed_p mail-tracking] } {
	    
	    db_dml update_acs_mail_log_sender    { update acs_mail_log set sender_id = :to_party_id where sender_id = :from_party_id }
	    db_dml update_acs_mail_log_recipient { update acs_mail_log set recipient_id = :to_party_id where recipient_id = :from_party_id }
	    
	}

	# Notifications
	# if contacts becomes ubiquitous enough this should be moved to a callback managed by the notifications package
	if { [apm_package_installed_p notifications] } {
	    
	    if { [contact::type -party_id $to_party_id] == "user" } {
		set update_user_info 1
	    } else {
		set update_user_info 0
	    }

	    set notifications [db_list_of_lists get_them { select type_id, request_id from notification_requests where user_id = :from_party_id }]
	    foreach notification $notifications {
		util_unlist $notification type_id request_id
		set existing_request_id [db_string get_it " select request_id from notification_requests where type_id = :type_id and user_id = :to_party_id and object_id = :request_id " -default {}]
		if { ![exists_and_not_null existing_request_id] } {
		    db_dml update_it " update notification_requests set user_id = :to_party_id where request_id = :request_id "
		    if { [string is true $update_user_info] } {
			db_dml update_it " update acs_objects set creation_user = :to_party_id where object_id = :request_id "
		    }
		}
	    }
	    
	}


	callback contacts::merge -from_party_id $from_party_id -to_party_id $to_party_id


        set rels [db_list_of_lists get_them " select rel_id, rel_type, object_id_one, object_id_two  from acs_rels where ( object_id_one = :from_party_id or object_id_two = :from_party_id )"]
	foreach rel $rels {
	    util_unlist $rel rel_id rel_type object_id_one object_id_two
	    if { $object_id_one == $from_party_id } {
		set object_id_one $to_party_id
	    } else {
		set object_id_two $to_party_id
	    }
	    set existing_rel_id [db_string existing_p " select rel_id from acs_rels where rel_type = :rel_type and object_id_one = :object_id_one and object_id_two = :object_id_two " -default {}]
	    if { ![exists_and_not_null existing_rel_id] } {
		db_dml update_it " update acs_rels set object_id_one = :object_id_one, object_id_two = :object_id_two where rel_id = :rel_id "
	    } else {
		ams::object_copy -from $rel_id -to $existing_rel_id
                # delete rel
		db_1row delete_it { select acs_rel__delete(:rel_id) }
	    }
	}

	# Application data links
	set party_links [application_data_link::get -object_id $to_party_id]
	foreach linked_object_id [application_data_link::get -object_id $from_party_id] {
	    if { [lsearch $party_links $linked_object_id] < 0 } {
		application_data_link::new -this_object_id $to_party_id -target_object_id $linked_object_id
	    }
	}
	application_data_link::delete_links -object_id $from_party_id


	# first we delete the contact_party_revisions
	db_dml update_it { update cr_items set live_revision = NULL, latest_revision = NULL where item_id = :from_party_id }
	db_list do_it { select content_revision__delete(revision_id) from cr_revisions where item_id = :from_party_id }
	db_dml delete_item { delete from cr_items where item_id = :from_party_id }

	# now we delete group membership
	db_list do_it { select acs_rel__delete(rel_id) from acs_rels where object_id_one = :from_party_id or object_id_two = :from_party_id }


	# update contexts
	db_dml update_it { update acs_objects set context_id = :to_party_id where context_id = :from_party_id }

	# now we update creation_user logs
	db_dml update_it { update acs_objects set creation_user = :to_party_id where creation_user = :from_party_id }
	db_dml update_it { update acs_objects set modifying_user = :to_party_id where modifying_user = :from_party_id }

	db_dml update_it { update group_element_index set element_id = :to_party_id where element_id = :from_party_id }
	db_dml update_it { delete from party_approved_member_map where party_id = :from_party_id and member_id = :from_party_id }
	db_dml update_it { update party_approved_member_map set member_id = :to_party_id where member_id = :from_party_id }
	db_dml update_it { update party_approved_member_map set party_id = :to_party_id where party_id = :from_party_id }


	if { [contact::type -party_id $from_party_id] == "user" } {
	    # nuke the user from the database
	    acs_user::delete -user_id $from_party_id -permanent
	} else {
	    db_dml delete_org_type { delete from organization_type_map where organization_id = :from_party_id }
	    db_exec_plsql permanent_delete { select acs_object__delete(:from_party_id)  }
	}
	
    } on_error {
	# something went wrong. this site might need a custom contacts::merge callback
	ad_return_error "Error." $errmsg
	ad_script_abort
    }
    
    foreach name [ns_cache names util_memoize] {
	ns_cache flush util_memoize $name
    } 
    contact::flush -party_id $to_party_id
    contact::flush -party_id $from_party_id

    ns_log notice "merge finished."


}

ad_proc contact::util::create_rel {
    {-object_id_one}
    {-object_id_two}
    {-rel_type}
} {
    Create a contacts rel
} {
    set rel_id [db_string rel_exists_p {} -default {}]
    if { $rel_id eq "" } {
        set context_id {}
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        set rel_id [db_exec_plsql create_rel {}]
        db_dml insert_contact_rel {}
    }
    return $rel_id
}
