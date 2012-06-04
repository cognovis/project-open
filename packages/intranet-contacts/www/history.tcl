ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-07-09
    @cvs-id $Id$


} {
    {party_id:integer}
    {page "comments"}
    {delete_object_id:integer ""}
    {return_url ""}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
    delete_requires_return_url -requires {delete_object_id} {
	if { $delete_object_id ne "" && $return_url == "" } {
	    ad_complain "[_ intranet-contacts.lt_Delete_requires_return_url]"
	}
    }
    delete_permission -requires {delete_object_id return_url} {
	set user_id [ad_conn user_id]
	if { [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege admin] } {
	    set delete_permission "all"
	} else {
	    set delete_permission [string tolower [parameter::get -parameter "DeleteHistoryPermission" -default "no"]]
	}
	if { [lsearch [list yours all] $delete_permission] < 0 } {
	    ad_complain "[_ intranet-contacts.lt_No_perm_to_delete_from_hist]"
	} elseif { $delete_permission eq "yours" } {
	    # we need to verify that they created this object
	    acs_object::get -object_id $delete_object_id -array acs_object
	    if { $user_id ne $acs_object(creation_user) } {
		ad_complain "[_ intranet-contacts.lt_No_perm_to_delete_from_hist]"
	    }
	}
    }
}

contact::require_visiblity -party_id $party_id

if { $delete_object_id ne "" && $return_url ne "" } {
    if { ![db_0or1row object_already_deleted_in_history {}] } {
	set user_id [ad_conn user_id]
	db_dml delete_object_from_history {}
	ad_returnredirect $return_url
	ad_script_abort
    }
}

ad_return_template
