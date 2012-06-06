ad_library {

    Support procs for the lists in the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2006-06-23
    @cvs-id $Id$

}

namespace eval contact:: {}
namespace eval contact::list:: {}


ad_proc -public contact::list::new {
    {-list_id ""}
    {-title:required}
    {-package_id ""}
} {
    create a contact list
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    set var_list [list \
                      [list list_id $list_id] \
                      [list title $title] \
                      [list package_id $package_id] \
		     ]

    return [package_instantiate_object -var_list $var_list contact_list]
}

ad_proc -public contact::list::delete {
    {-list_id:required}
} {
} {
    return [db_string delete_list { select contact_list__delete(:list_id) } -default {}]
}

ad_proc -public contact::list::member_add {
    {-list_id:required}
    {-party_id:required}
} {
    Add a party to a list
} {
    if { $party_id ne "" } {
	if { ![contact::list::member_p -list_id $list_id -party_id $party_id] } {
	    db_dml insert_member {
		insert into contact_list_members
                ( list_id, party_id )
                values
                ( :list_id, :party_id )
	    }
	}
    }
}

ad_proc -public contact::list::member_delete {
    {-list_id:required}
    {-party_id:required}
} {
    Delete a party from a list
} {
    db_dml insert_member {
	delete from contact_list_members where list_id = :list_id and party_id = :party_id
    }
}

ad_proc -public contact::list::member_p {
    {-list_id:required}
    {-party_id:required}
} {
    Add a party to a list
} {
    if { $party_id eq "" } {
	error "You must specify a party_id"
    }
    return [db_0or1row select_member_p { select 1 from contact_list_members where list_id = :list_id and party_id = :party_id }]
}

ad_proc -public contact::list::exists_p {
    {-list_id:required}
} {
} {
    return [db_0or1row select_list_p { select 1 from contact_lists where list_id = :list_id }]
}


ad_proc -public contact::owner_add {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    return [relation_add contact_owner $object_id $owner_id]
}

ad_proc -public contact::owner_delete {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    set rel_id [relation::get_id -object_id_one $object_id -object_id_two $owner_id -rel_type "contact_owner"]
    if { $rel_id ne "" } {
	relation_remove $rel_id
    }
}

ad_proc -public contact::owner_delete_all {
    {-object_id:required}
} {
} {
    foreach owner_id [db_list get_owners { select owner_id from contact_owners where object_id = :object_id }] {
	contact::owner_delete -object_id $object_id -owner_id $owner_id
    }
}

ad_proc -public contact::owner_p {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    return [db_0or1row getit { select 1 from contact_owners where object_id = :object_id and owner_id = :owner_id }]
}

ad_proc -public contact::owner_require {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    if { ![contact::owner_p -object_id $object_id -owner_id $owner_id] } {
	if { !${owner_id} } {
            auth::require_login
	} else {
            ns_log notice "contact::owner_require $owner_id (user [ad_conn user_id]) is not an owner of $object_id"
            ad_return_forbidden  "Permission Denied"  "<blockquote>You don't have sufficient permission.</blockquote>"
	}
        ad_script_abort
    }
}

ad_proc -public contact::owner_read_p {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    if { [contact::owner_p -object_id $object_id -owner_id $owner_id] } {
	return 1
    } elseif { [contact::owner_p -object_id $object_id -owner_id [ad_conn package_id]] } {
	return 1
    } else {
	return 0
    }

}

ad_proc -public contact::owner_require_read {
    {-object_id:required}
    {-owner_id:required}
} {
} {
    if { ![contact::owner_read_p -object_id $object_id -owner_id $owner_id] } {
	if { !${owner_id} } {
	    auth::require_login
	} else {
	    ns_log notice "contact::owner_require $owner_id (user [ad_conn user_id]) cannot read $object_id"
	    ad_return_forbidden  "Permission Denied"  "<blockquote>You don't have sufficient permission.</blockquote>"
	}
	ad_script_abort
    }
}

ad_proc -public contact::owner_count {
    {-object_id:required}
} {
    How many owners own this object?
} {
    return [db_string get_count { select count(1) from contact_owners where object_id = :object_id } -default {0}]
}

