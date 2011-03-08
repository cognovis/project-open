ad_page_contract {

    Create the club for an organization.

} {
    {party_id:integer}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

# First flush the site node cache

site_node::update_cache -sync_children -node_id 3061
catch {
    set fs_node [site_node::get -url /dotlrn/clubs/$party_id/file-storage]
    site_node::unmount -node_id [lindex $fs_node 3]
}

catch {
    set main_node [site_node::get -url /dotlrn/clubs/$party_id]
    site_node::unmount -node_id [lindex $main_node 3]
}

site_node::update_cache -sync_children -node_id 3061

ad_progress_bar_begin -title "[_ intranet-contacts.Creating_Club]" -message_1 "[_ intranet-contacts.lt_We_are_creating_the_c]" -message_2 "[_ intranet-contacts.lt_We_will_continue_auto]"

set group_id [group::get_id -group_name "Customers"]
callback contact::organization_new_group -organization_id $party_id -group_id $group_id

ad_progress_bar_end -url  [contact::url -party_id $party_id]
