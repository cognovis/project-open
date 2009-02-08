ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    object_id:integer,notnull
    return_url:notnull
    {remove_owner_id ""}
    {set_public_p ""}
} -validate {
    valid_object_and_ownership -requires {object_id} {
	# currently sharing is limited to contact_lists
	# in the future somebody might want to change this
	# to include things like contact_searches and other
	# object_types. Those should be added here.
        if { [lsearch [list contact_list] [acs_object_type $object_id]] < 0 } {
            ad_complain "[_ intranet-contacts.Insufficient_permission_to_edit_sharing]"
        } elseif { [db_string get_package_id { select package_id from acs_objects where object_id = :object_id } -default {}] ne [ad_conn package_id] } {
            ad_complain "[_ intranet-contacts.Insufficient_permission_to_edit_sharing]"
	} elseif { ![contact::owner_p -object_id $object_id -owner_id [ad_conn user_id]] } {
	    # the are not an explicit owner, but if this is public and they are an
	    # admin they are okay.
	    if { ![contact::owner_p -object_id $object_id -owner_id [ad_conn package_id]] || ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
		ad_complain "[_ intranet-contacts.Insufficient_permission_to_edit_sharing]"
	    }
        }
    }
    valid_remove_owner_id -requires {remove_owner_id} {
	if { ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] && [db_string getcreator { select creation_user from acs_objects where object_id = :object_id }] eq $remove_owner_id } {
	    ad_complain "[_ intranet-contacts.You_cannot_remove_creator_unless]"
	}
	if { [db_string getit { select count(1) from contact_owners where object_id = :object_id and owner_id in ( select party_id from parties ) }] eq "1" } {
	    ad_complain "[_ intranet-contacts.There_must_be_at_least_one_owner]"
	}
    }
    valid_set_public_p -requires {set_public_p} {
	if { $set_public_p ne "" && ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
	    ad_complain "[_ intranet-contacts.Only_admins_can_edit_public_settings]"
	}
    }
}


set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]
set url [ad_conn url]

if { $remove_owner_id ne "" } {
    contact::owner_delete -object_id $object_id -owner_id $remove_owner_id
    ad_returnredirect [export_vars -base $url -url {object_id return_url}]
    ad_script_abort
}

if { $set_public_p ne "" } {
    if { [string is true $set_public_p] } {
	contact::owner_add -object_id $object_id -owner_id [ad_conn package_id]	
    } elseif { [string is false $set_public_p] } {
	contact::owner_delete -object_id $object_id -owner_id [ad_conn package_id]	
    }
    ad_returnredirect [export_vars -base $url -url {object_id return_url}]
    ad_script_abort

}

set public_p [contact::owner_p -object_id $object_id -owner_id [ad_conn package_id]]
if { [string is true $public_p] } {
    set public_url [export_vars -base $url -url {object_id return_url {set_public_p 0}}]
} else {
    set public_url [export_vars -base $url -url {object_id return_url {set_public_p 1}}]
}

db_1row get_title_and_creator { select * from acs_objects where object_id = :object_id }


ad_form \
    -name "add_owner" \
    -method "POST" \
    -export {object_id return_url} \
    -form {
	{user_id:contact_search(contact_search) {label "[_ intranet-contacts.Add_new_owner]"} {search persons}}
    } -validate {
    } -on_submit {
	contact::owner_add -object_id $object_id -owner_id $user_id
    } -after_submit {
	ad_returnredirect [export_vars -base [ad_conn url] -url {object_id return_url}]
	ad_script_abort
    }

set user_id [ad_conn user_id]

template::list::create \
    -name "owners" \
    -row_pretty_plural "[_ intranet-contacts.owners]" \
    -elements {
        name {
	    label {}
	    link_url_eval $contact_url
	}
	email {
	    label {}
	    link_url_eval ${contact_url}message
	}
        action {
            label ""
            display_template {
		<a href="@owners.delete_url@"><img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" /></a>
            }
        }
    }



db_multirow -extend {contact_url delete_url name} -unclobber owners select_owners {
    
    select contact_owners.owner_id,
           parties.email
      from contact_owners, persons, parties
     where contact_owners.owner_id = persons.person_id
       and contact_owners.owner_id = parties.party_id
       and contact_owners.object_id = :object_id
    order by upper(persons.first_names), upper(persons.last_name)
} {
    set name [contact::name -party_id $owner_id]
    set contact_url [contact::url -party_id $owner_id]
    set delete_url [export_vars -base $url -url {object_id return_url {remove_owner_id $owner_id}}]
}
