ad_page_contract {
    Add / replace relationships between contacts.

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2006-05-02
} {
    party_ids
    object_id_two
    return_url
    rel_type
    remove_role_one
    remove_role_two
    {switch_roles_p 0}
} -properties {
    context:onevalue
    page_title:onevalue
}

set user_id [auth::require_login]
set page_title "[_ intranet-contacts.rel_bulk_add_confirm]"
set context [list [list "relationship-bulk-add" "[_ intranet-contacts.Add_Relationship]"] $page_title]

set confirm_options [list [list "[_ intranet-contacts.continue_with_delete]" t] [list "[_ intranet-contacts.cancel_and_return]" f]]

db_1row role_one_count {}
db_1row role_two_count {}

set contacts {}
foreach party $party_ids {
    lappend contacts [contact::link -party_id $party]
}
set contacts [join $contacts ", "]
set party_two [contact::link -party_id $object_id_two]

ad_form -name delete_confirm -action relationship-bulk-add-2 -export {return_url remove_role_one remove_role_two switch_roles_p party_ids rel_type} -form {
    {object_id_two:key}
}

if {$remove_role_one == "1"} {
    ad_form -extend -name delete_confirm -form {
	{contacts:text(inform) {label "[_ intranet-contacts.Add_relationship_to_these_contacts]"}}
	{role_one_count:text(inform) {label "[_ intranet-contacts.Add_relationship_role_one_count]"}}
    }
}

if {$remove_role_two == "1"} {
    ad_form -extend -name delete_confirm -form {
	{party_two:text(inform) {label "[_ intranet-contacts.Add_relationship_to_this_contact]"}}
	{role_two_count:text(inform) {label "[_ intranet-contacts.Add_relationship_role_two_count]"}}
    }
}

ad_form -extend -name delete_confirm -form {
    {confirmation:text(radio) {label " "} {options $confirm_options} {value f}}
}

ad_form -extend -name delete_confirm -edit_request {
} -after_submit {
    if {$confirmation} {
	ad_returnredirect [export_vars -base relationship-bulk-add-3 {party_ids object_id_two rel_type remove_role_one remove_role_two switch_roles_p return_url}]
    } else {
	ad_returnredirect $return_url
    }
    ad_script_abort
}

ad_return_template
