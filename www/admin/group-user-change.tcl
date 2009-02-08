ad_page_contract {

    Toggle the permission for users to edit their own attributes of this group.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {group_id:integer,notnull}
    {action:notnull}
    {return_url "./"}
} -validate {
    action_valid -requires {action} {
        if { [lsearch [list allow disallow] $action] < 0 } {
            ad_complain "[_ intranet-contacts.lt_the_action_supplied_i]"
        }
    }
}

# First flush our cache for the contact::groups as we change something here
util_memoize_flush contact::groups_list_not_cached

set package_id [ad_conn package_id]

switch $action {
    allow {
        db_dml allow_change {
            update contact_groups set user_change_p = 't' where group_id = :group_id and package_id = :package_id
        }
    }
    disallow {
        db_dml disallow_change {
            update contact_groups set user_change_p = 'f' where group_id = :group_id and package_id = :package_id
        }
    }
}


ad_returnredirect $return_url
