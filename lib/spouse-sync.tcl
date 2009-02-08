ad_page_contract {
    List and manage spouse relationship.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2006-05-22
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {return_url ""}
} -validate {
    contact_one_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	} else {
	    set spouse_id [contact::spouse_id_not_cached -party_id $party_id]
	    if { [llength $spouse_id] == "0" } {
		ad_complain "[_ intranet-contacts.lt_There_is_no_spouse]"
	    }
	}
    }
}


contact::require_visiblity -party_id $party_id

if { $return_url eq "" } { 
    set return_url "[contact::url -party_id $party_id]relationships"
}

set spouse_id [contact::spouse_id_not_cached -party_id $party_id]

# we display the attributes that will be synced whenever a user
# 
# the party_id is the primary spouse. Thus we copy the syncable attributes
# from that party to the spouse (by default). Before doing that we get the
# values to verify with the user that all is well with this.

set attribute_ids [contacts::spouse_sync_attribute_ids -package_id [ad_conn package_id]]


# we get the attributes in pretty name order.

set attributes [db_list_of_lists get_attributes {}]
set attributes [ams::util::localize_and_sort_list_of_lists -list $attributes]


set party_revision_id [contact::live_revision -party_id $party_id]
set spouse_revision_id [contact::live_revision -party_id $spouse_id]
set party_name [contact::name -party_id $party_id]
set spouse_name [contact::name -party_id $spouse_id]
set form_elements [list]

foreach attribute $attributes {
    util_unlist $attribute pretty_name attribute_id

    set party_value [ams::value -object_id $party_revision_id -attribute_id $attribute_id]
    set party_value_id [db_string get_party_value_id {} -default {}]
    set spouse_value [ams::value -object_id $spouse_revision_id -attribute_id $attribute_id]
    set spouse_value_id [db_string get_spouse_value_id {} -default {}]

    if { $party_value eq $spouse_value && $party_value ne "" } {
	# the attribute value is already the same, we assume
        # that this is retained
	continue
    }


    set options [list]
    if { $party_value ne "" } {
	set attr${attribute_id}_value $party_value_id
	lappend options [list "<strong>$party_name:</strong><br>$party_value<br><br>" $party_value_id]
    }
    if { $spouse_value ne "" } {
	if { ![exists_and_not_null attr${attribute_id}_value] } {
	    set attr${attribute_id}_value $spouse_value_id
	}
	lappend options [list "<strong>$spouse_name:</strong><br>$spouse_value<br><br>" $spouse_value_id]
    }
    if { [llength $options] > 0 } {
	lappend options [list "<strong>[_ intranet-contacts.Delete]</strong><br><br>" "0"]
	lappend form_elements [list attr${attribute_id}:integer(radio) \
				   [list label $pretty_name] \
				   [list options $options] \
				  ]

    }

}

if { [llength $form_elements] == 0 } { 
    ad_returnredirect $return_url
    ad_script_abort
}


ad_form \
    -name "spouse_sync" \
    -method "GET" \
    -export {return_url} \
    -form $form_elements \
    -on_request {
	foreach element [template::form::get_elements spouse_sync] {
	    if { [regexp {^attr[0-9]} $element match] } {
		set $element [set ${element}_value]
	    }
	}
    } -on_submit {

	# we first set up a new contact revision for each contact
	set new_party_revision_id [contact::revision::new -party_id $party_id]
	ams::object_copy -from $party_revision_id -to $new_party_revision_id

	set new_spouse_revision_id [contact::revision::new -party_id $spouse_id]
	ams::object_copy -from $spouse_revision_id -to $new_spouse_revision_id
	
	# now we save the values specified
	foreach element [template::form::get_elements spouse_sync] {
	    if { [regexp {^attr([0-9]{1,})$} $element match attribute_id] } {
		set value_id [set ${element}]

		if { $value_id eq "0" } {
		    # the value should be deleted
		    set value_id ""		    
		}
		ams::attribute::value_save -object_id $new_party_revision_id -attribute_id $attribute_id -value_id $value_id
		ams::attribute::value_save -object_id $new_spouse_revision_id -attribute_id $attribute_id -value_id $value_id

	    }
	}
	
	contact::flush -party_id $party_id
	contact::flush -party_id $spouse_id
	contact::search::flush_results_counts

	ad_returnredirect $return_url
    }
