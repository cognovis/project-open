ad_page_contract {
    Move existing relationships to other contact.

    @author Timo Hentschel timo@timohentschel.de
    @creation-date 2006-04-19
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {party_two:optional}
    {query ""}
    {orderby "role,asc"}
    {rel_id:multiple}
} -validate {
    contact_one_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_first_contact_spe]"
	}
    }
    contact_two_exists -requires {party_two} {
	if { ![contact::exists_p -party_id $party_two] } {
	    ad_complain "[_ intranet-contacts.lt_The_second_contact_sp]"
	}
    }

}
contact::require_visiblity -party_id $party_id

set return_url "$party_id/relationships"
set party_ids [db_list get_other_party_ids {}]
set roles [db_list_of_lists all_roles {}]

if {[llength $roles] > 1} {
    error "[_ intranet-contacts.lt_neither_person_nor_or]"
    ad_script_abort
}

set role_one [lindex [lindex $roles 0] 0]
set role_two [lindex [lindex $roles 0] 1]
set switch_roles_p [lindex [lindex $roles 0] 2]

ad_returnredirect [export_vars -base relationship-bulk-add {party_ids return_url role_one role_two switch_roles_p {remove_role_one 1}}]
