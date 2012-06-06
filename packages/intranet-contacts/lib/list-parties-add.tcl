ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,multiple,optional}
    {party_ids:optional}
    {return_url "./"}
    {list_id:integer ""}
} -validate {
    valid_party_submission {
	if { ![exists_and_not_null party_id] && ![exists_and_not_null party_ids] } { 
	    ad_complain "[_ intranet-contacts.lt_Your_need_to_provide_]"
	}
    }
    valid_list_id -requires {list_id} {
	if { ![contact::owner_p -object_id $list_id -owner_id [ad_conn user_id]] } {
	    ad_complain "[_ intranet-contacts.You_do_not_own_this_list]"
	}
    }
}

if { [exists_and_not_null party_id] } {
    set party_ids [list]
    foreach party_id $party_id {
	lappend party_ids $party_id
    }
}
foreach id $party_ids {
    contact::require_visiblity -party_id $id
}

if { [llength $party_ids] eq 1 && $list_id ne "" } {
    # this is a request to add one party to one
    # list
    contact::list::member_add -list_id $list_id -party_id [lindex $party_ids 0]
    contact::search::flush_results_counts
    ad_returnredirect $return_url
    ad_script_abort
}


set title "[_ intranet-contacts.Add_to_List]"
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]
set context [list $title]
set package_id [ad_conn package_id]
set recipients [list]
foreach party_id $party_ids {
    lappend recipients "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a>"
}
set recipients [join $recipients ", "]

set form_elements {
    party_ids:text(hidden)
    return_url:text(hidden)
    {recipients:text(inform),optional {label "[_ intranet-contacts.Contacts]"}}
}

set list_options [db_list_of_lists get_lists { select ao.title, cl.list_id from contact_lists cl, acs_objects ao where cl.list_id = ao.object_id and cl.list_id in ( select object_id from contact_owners where owner_id in ( :user_id, :package_id )) order by upper(ao.title) }]

if { [llength $list_options] == "0" } {
    ad_return_error "[_ intranet-contacts.No_Lists]" "[_ intranet-contacts.You_do_not_own_any_lists]"
}

append form_elements {
    {list_ids:text(checkbox),multiple {label "[_ intranet-contacts.Add_to_Lists]"} {options $list_options}}
}
set edit_buttons [list [list "[_ intranet-contacts.lt_Add_to_Selected_Lists]" create]]




ad_form -name add_to_list \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
	db_transaction {
            foreach list_id $list_ids {
                foreach party_id $party_ids {
		    contact::list::member_add -list_id $list_id -party_id $party_id
                }
            }
	}
    } -after_submit {
	contact::search::flush_results_counts
	ad_returnredirect $return_url
	ad_script_abort
    }



