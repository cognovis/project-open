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
}

set user_id [auth::require_login]

db_transaction {
    if { $remove_role_two eq "1" } {
	set party_id $object_id_two
	db_list delete_all_rels {}
    }

    set context_id {}
    set creation_user $user_id
    set creation_ip [ad_conn peeraddr]

    foreach object_id_one $party_ids {
	if { $remove_role_one eq "1" } {
	    set party_id $object_id_one
	    db_list delete_all_rels {}
	}
	set existing_rel_id [db_string rel_exists_p {} -default {}]
	if { [empty_string_p $existing_rel_id] } {
	    set rel_id {}
	    if {$switch_roles_p} {
		set rel_id [db_exec_plsql create_backward_rel {}]
	    } else {
		set rel_id [db_exec_plsql create_forward_rel {}]
	    }
	    db_dml insert_contact_rel {}
	}
	contact::flush -party_id $object_id_one
    }
    contact::flush -party_id $object_id_two
}

ad_returnredirect $return_url
