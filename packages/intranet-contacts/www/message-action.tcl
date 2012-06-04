ad_page_contract {
    List and manage contacts.
 
    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {item_id:integer}
    {owner_id:integer ""}
    {action}
    {return_url ""}
} -validate {
    item_exists -requires {item_id} {
	if { ![db_0or1row message_exists_p { select 1 from contact_messages where item_id = :item_id}] && ![exists_and_not_null message_type]} {
	    ad_complain [_ intranet-contacts.lt_The_message_id_specified_does_not_exist]
	}
    }
    action_valid -requires {action} {
	if { [lsearch [list move copy delete] $action] < 0 } {
	    ad_complain [_ intranet-contacts.The_action_specified_is_invalid]
	} elseif { ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
            set message_owner_id [db_string get_owner_id { select owner_id from contact_messages where item_id = :item_id}]
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
                    if { $message_owner_id != [ad_conn user_id] } {
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

db_1row select_message_info {}
set package_id [ad_conn package_id]


switch $action {
    "move" {
        db_dml update_owner {}
        util_user_message -html -message [_ intranet-contacts.The_message_-title-_was_made_public]
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
	contact::message::save \
	    -item_id $new_item_id \
	    -owner_id $owner_id \
	    -message_type $message_type \
	    -title $title \
	    -description $description \
	    -content $content \
	    -content_format $content_format
        util_user_message -html -message [_ intranet-contacts.The_message_-title-_was_copied_to_your_messages]
    }
    "delete" {
	db_dml expire_message {}
        util_user_message -html -message [_ intranet-contacts.The_message_-title-_was_deleted]

    }
}

if { ![exists_and_not_null return_url] } {
    set return_url [export_vars -base "messages" -url {owner_id}]
}

ad_returnredirect $return_url
ad_script_abort
