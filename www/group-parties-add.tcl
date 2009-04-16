ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {object_id:integer,multiple,optional}
    {party_id:multiple,optional}
    {party_ids ""}
    {return_url "./"}
}

if { [exists_and_not_null party_id] } {
    foreach p_id $party_id {
        if {[lsearch $party_ids $p_id] < 0} {
	        lappend party_ids $p_id
        }
    }
} 

# Deal with object_ids passed in
if { [exists_and_not_null object_id] } {
    foreach p_id $object_id {
        if {[lsearch $party_ids $p_id] < 0} {
	        lappend party_ids $p_id
        }
    }
}

foreach id $party_ids {
    contact::require_visiblity -party_id $id
}


set title "[_ intranet-contacts.Add_to_Group]"
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

set group_options [contact::groups -expand "all" -privilege_required "create"]
if { [llength $group_options] == "0" } {
    ad_return_error "[_ intranet-contacts.lt_Insufficient_Permissi]" "[_ intranet-contacts.lt_You_do_not_have_permi]"
}

append form_elements {
    {group_ids:text(checkbox),multiple {label "[_ intranet-contacts.Add_to_Groups]"} {options $group_options} {}}
}
set edit_buttons [list [list "[_ intranet-contacts.lt_Add_to_Selected_Group]" create]]




ad_form -action group-parties-add \
    -name add_to_group \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
	db_transaction {
            foreach group_id $group_ids {
                foreach party_id $party_ids {
                    ds_comment "groups: $group_id $party_id"
		            group::add_member -group_id $group_id -user_id $party_id -member_state "approved"
                }
            }
	}
    } -after_submit {
	contact::search::flush_results_counts
	ad_returnredirect $return_url
	ad_script_abort
    }


