ad_page_contract {
    List and manage contacts.
 
    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {search_id:integer}
    {owner_id:integer ""}
    {action}
    {return_url ""}
} -validate {
    valid_search_id -requires {search_id} {
	if { ![contact::search::exists_p -search_id $search_id] } {
	    ad_complain [_ intranet-contacts.The_search_id_sepecified_does_not_exist]
	}
    }
    action_valid -requires {action} {
	if { [lsearch [list move copy delete] $action] < 0 } {
	    ad_complain [_ intranet-contacts.The_action_specified_is_invalid]
	} elseif { ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
            set search_owner_id [contact::search::owner_id -search_id $search_id]
            switch $action {
                "move" {
                        ad_complain [_ intranet-contacts.You_do_not_have_permission_to_move_searches]
                }
                "copy" {
                    if { $owner_id != [ad_conn user_id] } {
                        ad_complain [_ intranet-contacts.You_cannot_copy_searches_to_somebody_other_than_yourself]
                    }
                }
                "delete" {
                    if { $search_owner_id != [ad_conn user_id] } {
                        ad_complain [_ intranet-contacts.You_cannot_delete_searches_that_do_not_belong_to_you]
                    }
                }
            }
        }
    }
    owner_valid -requires {owner_id} {
        if { [exists_and_not_null owner_id] } {
            if { $owner_id == [ad_conn package_id] || ( [contact::exists_p -party_id $owner_id] && [lsearch [list person user] [contact::type -party_id $owner_id]] >= 0 ) } {
            } else {
                ad_complain [_ intranet-contacts.The_owner_id_specified_is_not_valid]
            }
        }
    }
}

db_1row select_search_info {}
set package_id [ad_conn package_id]


switch $action {
    "move" {
        db_dml update_owner {}
        util_user_message -html -message [_ intranet-contacts.The_search_-title-_was_made_public]
    }
    "copy" {
        regsub -all "'" $title "''" sql_title 
        set similar_titles [db_list select_similar_titles {}]
        set number 1
        set orig_title $title
        while { [lsearch $similar_titles $title] >= 0 } {
            set title "$orig_title ($number)"
            incr number
        }
        set new_search_id [contact::search::new -title $title -owner_id $owner_id -all_or_any $all_or_any -object_type $object_type]
        db_foreach select_search_conditions {} {
            contact::search::condition::new -search_id $new_search_id -type $type -var_list $var_list
        }
        util_user_message -html -message [_ intranet-contacts.The_search_-title-_was_copied_to_your_searches]
    }
    "delete" {
        contact::search::delete -search_id $search_id
        util_user_message -html -message [_ intranet-contacts.The_search_-title-_was_deleted]
    }
}

if { ![exists_and_not_null return_url] } {
    set return_url [export_vars -base "searches" -url {owner_id}]
}

ad_returnredirect $return_url
ad_script_abort
