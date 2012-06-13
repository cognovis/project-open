ad_page_contract {
    Add a contact relationship

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-05-15
    @cvs-id $Id$
} {
    {party_one:integer,notnull}
    {role_one:optional}
    {party_two:integer,notnull}
    {role_two:notnull}
    {rel_type:optional}
    {return_url ""}
} -validate {
    contact_one_exists -requires {party_one} {
	if { ![contact::exists_p -party_id $party_one] } {
	    ad_complain "[_ intranet-contacts.lt_The_first_contact_spe]"
	}
    }
    contact_two_exists -requires {party_two} {
	if { ![contact::exists_p -party_id $party_two] } {
	    ad_complain "[_ intranet-contacts.lt_The_second_contact_sp]"
	}
    }
    role_one_exists -requires {role_one} {
        set role $role_one
	if { ![db_0or1row role_exists_p {}] } {
	    ad_complain "[_ intranet-contacts.lt_The_first_role_specif]"
	}
    }
    role_two_exists -requires {role_two} {
        set role $role_two
	if { ![db_0or1row role_exists_p {}] } {
	    ad_complain "[_ intranet-contacts.lt_The_second_role_speci]"
	}
    }
}
contact::require_visiblity -party_id $party_one
contact::require_visiblity -party_id $party_two

set package_id [ad_conn package_id]
set party_id $party_one
set contact_name_one [contact::name -party_id $party_id]
set contact_name_two [contact::name -party_id $party_two]
set contact_type_one [contact::type -party_id $party_id]
if { $contact_type_one == "user" } {
    set contact_type_one "person"
}
set contact_type_two [contact::type -party_id $party_two]
if { $contact_type_two == "user" } {
    set contact_type_two "person"
}

set secondary_role_pretty [lang::util::localize [db_string get_secondary_role_pretty {}]]
if { ![exists_and_not_null rel_type] } {
    set options_list [db_list_of_lists get_rel_types {}]
    set options_length [llength $options_list]
    if { $options_length == "0" } {
        ad_return_error "[_ intranet-contacts.Error]" "[_ intranet-contacts.lt_There_was_a_problem_w]"
    } elseif { $options_length == "1" } {
        set rel_type [lindex [lindex $options_list 0] 0]
        set role_one [lindex [lindex $options_list 0] 1]
    } else {
        multirow create rel_types rel_type primary_role_pretty url
        foreach rel $options_list {
            set temp_rel_type [lindex $rel 0]
            set temp_role_one [lindex $rel 1]
            set temp_role_pretty [lindex $rel 2]
            multirow append rel_types $temp_rel_type $temp_role_pretty [export_vars -base "relationship-add" -url {party_one party_two role_two {role_one $temp_role_one} {rel_type $temp_rel_type}}]
        }
    }
}




if { [exists_and_not_null rel_type] } {

    if { $contact_type_one eq "person" } {
	callback contact::person_new_rel -package_id $package_id -party_id $party_id -object_id_two $party_two -rel_type $rel_type
    } else {
	callback contact::organization_new_rel -package_id $package_id -party_id $party_id -object_id_two $party_two -rel_type $rel_type
    }
    contact::flush -party_id $party_id
    contact::flush -party_id $party_two

    db_1row get_roles {}

    if { $db_role_one == $role_one } {
        set object_id_one $party_one
        set object_id_two $party_two
    } else {
        set object_id_one $party_two
        set object_id_two $party_one
    }
    if { ![exists_and_not_null return_url] } {
        set return_url "${party_id}/relationships"
    }
    ad_returnredirect [export_vars -base "relationship-ae" -url {object_id_one object_id_two rel_type return_url {party_id $party_one}}]
    ad_script_abort
}

