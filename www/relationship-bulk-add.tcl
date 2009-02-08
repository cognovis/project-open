ad_page_contract {

    @author Matthew Geddert (openacs@geddert.com)
    @creation-date 2006-03-12
    @cvs-id $Id$

} {
    {party_id:integer,multiple ""}
    {party_ids ""}
    {return_url}
    {role_one ""}
    {role_two ""}
    {remove_role_one:optional}
}

set title [_ intranet-contacts.Add_Relationship]
set context [list $title]
set names [list]
set contact_type [list]
if { ![exists_and_not_null party_ids] } {
    set party_ids $party_id
}
set organizations [list]
set organization_ids [list]
set people [list]
set person_ids [list]
foreach party $party_ids {
    contact::require_visiblity -party_id $party
    if { [contact::type -party_id $party] eq "organization" } {
	lappend organizations [contact::link -party_id $party]
	lappend organization_ids $party
    } else {
	lappend people [contact::link -party_id $party]
	lappend person_ids $party
    }
}

if { [llength $organization_ids] > 0 && [llength $person_ids] > 0 } {
    ad_complain [_ intranet-contacts.lt_You_need_parties_to_bulk_update]
} elseif { [llength $person_ids] > 0 } {
    set contact_type "person"
} elseif { [llength $organization_ids] > 0 } {
    set contact_type "organization"
}
set organizations [join $organizations ", "]
set people [join $people ", "]


set object_types [list "party" $contact_type]
set rel_two_options [db_list_of_lists get_rels {}]
set rel_two_options [ams::util::localize_and_sort_list_of_lists -list $rel_two_options]
set rel_two_options [concat [list [list "" ""]] [lang::util::localize $rel_two_options]]

if { $role_two ne "" && $role_one ne "" } {
    # we verify that the role still exists
    # if not we set role_one to zero
    # this also gets values needed by the validation block
    if { ![db_0or1row get_rel_info {}] } {
	set role_one ""
    }
}

if { $role_two ne "" } {
    set role_one_options [lang::util::localize [ams::util::localize_and_sort_list_of_lists -list [db_list_of_lists get_rel_types {}]]]
    if { [llength $role_one_options] == "0" } {
	ad_return_error "[_ intranet-contacts.Error]" "[_ intranet-contacts.lt_There_was_a_problem_w]"
    } elseif { [llength $role_one_options] == "1" } {
	set role_one [lindex [lindex $role_one_options 0] 1]
	set role_one_pretty [lindex [lindex $role_one_options 0] 0]
    } else {
	set role_one_options [concat [list [list "" ""]] $role_one_options]
	set role_one ""
    }
}


ad_form -name "add_edit" -method "GET" -export {party_ids return_url} -form {
    {remove_role_one:boolean(checkbox),optional
	{label ""}
	{options {{"[_ intranet-contacts.lt_Remove_others_of_this_role_from_these_contacts]" 1}}}
    }
    {people:text(inform) {label "[_ intranet-contacts.lt_Add_relationship_to_these_people]"}}
    {organizations:text(inform) {label "[_ intranet-contacts.lt_Add_relationship_to_these_orgs]"}}
}

if { $role_two ne "" && $role_one eq "" } {
    ad_form -extend -name "add_edit" -form {
	{role_one:text(select)
	    {label "[_ intranet-contacts.Role_for_these_contacts]"}
	    {options $role_one_options}
	}
    }
} elseif { $role_two ne "" && $role_one ne "" } {
    ad_form -extend -name "add_edit" -form {
	{role_one:text(hidden)
	    {label ""}
	    {value "$role_one"}
	}
	{role_one_pretty:text(inform)
	    {label "[_ intranet-contacts.Role_for_these_contacts]"}
	}
    }
    # value has to be set this way to override on refreshes
    template::element::set_value add_edit role_one $role_one
    template::element::set_value add_edit role_one_pretty $role_one_pretty
    ## [lang::util::localize [db_string get_role_one_pretty {}]]
} else {
    ad_form -extend -name "add_edit" -form {
	{role_one:text(hidden),optional}
	{role_one_pretty:text(inform)
	    {label "[_ intranet-contacts.Role_for_these_contacts]"}
	    {value "[_ intranet-contacts.dependent_on_role_of_related_contact]"}
	}
    }
}

ad_form -extend -name "add_edit" -form {
    {role_two:text(select)
	{label "[_ intranet-contacts.Role_of_related_contact]"}
	{options $rel_two_options}
	{section "[_ intranet-contacts.Related_contact]"}
    }
    {object_id_two:contact_search(contact_search) {label "[_ intranet-contacts.Related_contact]"}}
    {remove_role_two:boolean(checkbox),optional
	{label ""}
	{options {{"[_ intranet-contacts.lt_Remove_others_of_this_role_from_this_related_contact]" 1}}}
    }
    {add:text(submit) {label "[_ intranet-contacts.Add_Relationship]"}}
} -on_request {
} -edit_request {
} -on_refresh {
} -validate {
} -on_submit {
    db_transaction {
	if { ![db_0or1row get_rel_info {}] } {
	    break
	}
	set object_type_two [contact::type -party_id $object_id_two]
	if { $object_type_two eq "organization" && [lsearch [list person party] $secondary_object_type] >= 0 } {
	    template::element::set_error add_edit object_id_two [_ intranet-contacts.The_selected_relationship_requires_related_person]
	}
	if { $object_type_two ne "organization" && [lsearch [list organization party] $secondary_object_type] >= 0 } { 
	    template::element::set_error add_edit object_id_two [_ intranet-contacts.The_selected_relationship_requires_related_org]
	}
	if { ![template::form::is_valid add_edit] } {
	    break
	}
    }

    #171498 kopieren duplicate key

} -after_submit {
    # we need to determine if this relationship is switched.
    if { $role_one eq [db_string get_role_one {}] } {
	set switch_roles_p 0
    } else {
	set switch_roles_p 1
    }

    #[db_string get_it { select role_one from acs_rel_types where rel_type }
    if { $remove_role_one eq "1" || $remove_role_two eq "1" } {
	ad_returnredirect [export_vars -base relationship-bulk-add-2 {party_ids object_id_two rel_type return_url remove_role_one remove_role_two switch_roles_p}]
    } else {
	ad_returnredirect [export_vars -base relationship-bulk-add-3 {party_ids object_id_two rel_type return_url remove_role_one remove_role_two switch_roles_p}]
    }
}


if { [template::element::get_value add_edit organizations] eq "" } {
    template::element::set_properties add_edit organizations widget hidden
}
if { [template::element::get_value add_edit people] eq "" } {
    template::element::set_properties add_edit people widget hidden
}

ad_return_template
