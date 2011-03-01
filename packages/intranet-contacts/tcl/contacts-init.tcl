ad_library {

    Init file for contacts

    @author Matthew Geddert (openacs@geddert.com)
    @creation-date 2004-08-16
}

# This will be run every 5 minutes, so that if other
# packages create objects (such as users creating
# accounts for themselves) content_items and content_revisions
# are automatically create. This is needed for contacts
# searches to work correctly.

nsv_set contacts sweeper_p 0
ad_schedule_proc -thread t 300 contacts::sweeper

if {[empty_string_p [info procs callback]]} {

    ns_log notice "CONTACTS: callback proc didn't exist so we are adding it here"
    ad_proc -public callback {
	-catch:boolean
	{-impl *}
	callback
	args
    } {
	Placeholder for contacts to work on 5.1
    } {
    }
}


if { [empty_string_p [info procs rel_types::create_role]] } {

    ns_log notice "CONTACTS: rel_types::create_role proc didn't exist so we are adding it here"
    namespace eval rel_types {}
    ad_proc -public rel_types::create_role {
	{-pretty_name:required}
	{-pretty_plural:required}
	{-role}
    } {

	Create a new Relationship Role

	@author Malte Sussdorff (sussdorff@sussdorff.de)
	@creation-date 2005-06-04

	@param pretty_name

	@param pretty_plural

	@param role

	@return 1 if successful
    } {
	if {![exists_and_not_null role]} {
	    set role [util_text_to_url \
			  -text $pretty_name \
			  -replacement "_" \
			  -existing_urls [db_list get_roles {}]]
	}

	set return_code 1

	db_transaction {

	    # Force internationalisation of Roles

	    # Internationalising of Attributes. This is done by storing the
	    # attribute with it's acs-lang key

	    set message_key "role_${role}"

	    # Register the language keys

	    lang::message::register en_US contacts $message_key $pretty_name
	    lang::message::register en_US contacts "${message_key}_plural" $pretty_plural

	    # Replace the pretty_name and pretty_plural with the message key, so
	    # it is inserted correctly in the database

	    set pretty_name "#contacts.${message_key}#"
	    set pretty_plural "#contacts.${message_key}_plural#"
	    db_exec_plsql create_role {
		select acs_rel_type__create_role(:role, :pretty_name, :pretty_plural)
            }
	} on_error {
	    error $errmsg
	    set return_code 0
	}
	return $return_code
    }


}

if {[empty_string_p [info procs application_data_link::get_linked]]} {

    ns_log notice "CONTACTS: application_data_link::get_linked proc didn't exist so we are adding it here"
    namespace eval application_data_link {}
    ad_proc -public application_data_link::get_linked {
	args
    } {
	Placeholder for contacts to work on 5.1
    } {
	return {}
    }

}

if {[empty_string_p [info procs application_link::get_linked]]} {

    ns_log notice "CONTACTS: application_link::get_linked proc didn't exist so we are adding it here"
    namespace eval application_link {}
    ad_proc -public application_link::get_linked {
	args
    } {
	Placeholder for contacts to work on 5.1
    } {
	return {}
    }

}

