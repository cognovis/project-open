ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {object_type}
    {object_id_two ""}
    {role_two ""}
} 


set title "[_ intranet-contacts.Add_new_in_Group]"
set user_id [ad_conn user_id]
set context [list $title]
set package_id [ad_conn package_id]

set form_elements {
    object_type:text(hidden)
}

if {![string eq "" $object_id_two]} {
    lappend form_elements "object_id_two:text(hidden)"
    lappend form_elements "role_two:text(hidden)"
}
set default_group [contacts::default_group]
set group_options [contact::groups -privilege_required "create"]
if { [llength $group_options] == "0" } {
    # only the default group is available to this user
    set group_ids $default_group
    ad_returnredirect [export_vars -base "add/${object_type}" -url {object_type group_ids object_id_two role_two}]
#    ad_return_error "[_ intranet-contacts.lt_Insufficient_Permissi]" "[_ intranet-contacts.lt_You_do_not_have_permi]"
}

# If we have a group named like the role select it by default
set role_group_id [group::get_id -group_name $role_two]
set group_options [lsort -index 0 $group_options]
append form_elements {
    {group_ids:text(checkbox),multiple,optional {label "[_ intranet-contacts.Add_to_Groups]"} {values $role_group_id} {options $group_options}}
}
set edit_buttons [list [list "[_ intranet-contacts.lt_Add_new_in_Selected_Groups]" create]]

ad_form \
    -name group-parties-add \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url "." \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
    } -after_submit {
	# the contact needs to be added to the default group
	lappend group_ids $default_group
	ad_returnredirect [export_vars -base "add/${object_type}" -url {object_type group_ids role_two object_id_two}]
	ad_script_abort
    }


