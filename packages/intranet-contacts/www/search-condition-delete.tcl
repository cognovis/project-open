ad_page_contract {
    Delete a search condition.
 
    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {condition_id:integer}
} -validate {
    valid_condition -requires {condition_id} {
	db_0or1row condition_exists_p {
                                        select cs.owner_id
                                          from contact_search_conditions csc,
                                               contact_searches cs
                                         where csc.condition_id = :condition_id
                                           and csc.search_id = cs.search_id
                                      }
        if { ![exists_and_not_null owner_id] } {
            ad_complain "[_ intranet-contacts.You_have_specified_an_invalid_search_condition]"
        } else { 
	    set valid_owner_ids [list]
	    lappend valid_owner_ids [ad_conn user_id]
	    if { [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
		lappend valid_owner_ids [ad_conn package_id]
	    }
	    if { [lsearch $valid_owner_ids $owner_id] < 0 } {
		if { [contact::exists_p -party_id $owner_id] } {
		    ad_complain "[_ intranet-contacts.You_do_not_have_permission_to_delete_other_peoples_search_conditions]"
		} else {
		    ad_complain "[_ intranet-contacts.You_do_not_have_permission_to_delete_this_condition]"
		}
	    }
	}
    }
}

db_1row get_search_id { select search_id, var_list, type from contact_search_conditions where condition_id = :condition_id }
contact::search::condition::delete -condition_id $condition_id
contact::search::flush -search_id $search_id
set condition [contacts::search::condition_type -type $type -request pretty -var_list $var_list]

util_user_message -html -message [_ intranet-contacts.The_condition_-condition-_was_deleted]
ad_returnredirect [export_vars -base "search" -url { search_id }]
