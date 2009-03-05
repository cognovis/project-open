# packages/contacts/lib/contact-relationships.tcl
#
# Include for the relationships of a contact
#
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-21
# @arch-tag: 291a71c2-5442-4618-bb9f-13ff23d854b5
# @cvs-id $Id$

foreach required_param {party_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {package_id} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {[empty_string_p $package_id]} {
    set package_id [contact::package_id -party_id $party_id]
}

if {![exists_and_not_null sort_by_date_p]} {
    set sort_by_date_p 0
}

if {$sort_by_date_p} {
    set sort_order "creation_date desc"
} else {
    set sort_order upper(other_name)
}

multirow create rels relationship relation_url rel_id contact contact_url attribute value creation_date role

db_foreach get_relationships {} {
	set contact_url [contact::url -party_id $other_party_id]
	set other_object_type [acs_object_type $other_party_id]
	if {[string eq $rel_type "contact_rels_employment"]} {
	    set relation_url [export_vars -base "[apm_package_url_from_id $package_id]add/$other_object_type" -url {{object_id_two "$party_id"} rel_type return_url}]    
	} else {
	    set relation_url ""
	}
	
	set creation_date [lc_time_fmt $creation_date %q]
	set role_singular [lang::util::localize $role_singular]
	set other_name [contact::name -party_id $other_party_id -reverse_order]
	multirow append rels $role_singular $relation_url $rel_id $other_name $contact_url {} {} $creation_date $role
	
	# NOT YET IMPLEMENTED - Checking to see if role_singular or role_plural is needed
	
	if { [ams::list::exists_p -object_type ${rel_type} -list_name ${package_id}] } {
	    set details_list [ams::values -package_key "contacts" -object_type $rel_type -list_name $package_id -object_id $rel_id -format "text"]
	    
	    if { [llength $details_list] > 0 } {
		foreach {section attribute_name pretty_name value} $details_list {
		    multirow append rels $role_singular $relation_url $rel_id $other_name $contact_url $pretty_name $value $creation_date $role
		}
	    }
	}
}

switch [acs_object_type $party_id] {
    im_office {
	# Now deal with offices
	# First get the companies where it is a main office
	set main_office_companies [db_list main_offices "select company_id from im_companies where main_office_id = :party_id"]
	foreach main_office_company $main_office_companies {
	    set contact_url [contact::url -party_id $main_office_company]
	    set other_name [contact::name -party_id $main_office_company -reverse_order]	    
	    multirow append rels "Company (Main Office)" "" "$main_office_company"  $other_name $contact_url {} {} {} "Main Office"
	}
	if {$main_office_companies eq ""} {
	    set main_office_companies 0
	}
	set office_companies [db_list offices "select company_id from im_offices
             where office_id = :party_id and 
                   company_id not in ([template::util::tcl_to_sql_list $main_office_companies])"]
	foreach office_company $office_companies {
	    set contact_url [contact::url -party_id $office_company]
	    set other_name [contact::name -party_id $office_company -reverse_order]	    
	    multirow append rels "Company" "" "$office_company"  $other_name $contact_url {} {} {} "Office"
	}
    }

    im_company {
	# First get the main office
	set main_office_id [db_list main_office "select main_office_id from im_companies where company_id = :party_id"]
	set contact_url [contact::url -party_id $main_office_id]
	set other_name [contact::name -party_id $main_office_id -reverse_order]	    
	multirow append rels "Main Office" "" "$main_office_id"  $other_name $contact_url {} {} {} "Main Office"

	set office_ids [db_list offices "select office_id from im_offices
             where company_id = :party_id and 
                   office_id not in (:main_office_id)"]
	foreach office_id $office_ids {
	    set contact_url [contact::url -party_id $office_id]
	    set other_name [contact::name -party_id $office_id -reverse_order]	    
	    multirow append rels "Office" "" "$office_id"  $other_name $contact_url {} {} {} "Company"
	}
    }

}
	    
template::multirow sort rels role contact