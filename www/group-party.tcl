ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,multiple}
    {group_id:integer,multiple}
    {return_url "./"}
} -validate {
}
if { [exists_and_not_null party_id] } {
    set party_ids [list]
    foreach party_id $party_id {
	lappend party_ids $party_id
    }
}



set title "Add to Group"
set user_id [ad_conn user_id]
set context [list $title]
set package_id [ad_conn package_id]
set recipients [list]
foreach party_id $party_ids {
    contact::require_visiblity -party_id $party_id
    lappend recipients "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a>"
}
set recipients [join $recipients ", "]

set form_elements {
    party_ids:text(hidden)
    return_url:text(hidden)
    {recipients:text(inform),optional {label "Contacts"}}
}

set group_options [contact::groups -expand "all" -privilege_required "create"]
if { [llength $group_options] == "0" } {
    ad_return_error "Insufficient Permissions" "You do not have permission to add users to groups"
}

append form_elements {
    {group_ids:text(checkbox),multiple {label "Add to Group(s)"} {options $group_options}}
}
set edit_buttons [list [list "Add to Selected Groups" create]]




ad_form -action group-parties-add \
    -name add_to_group \
    -cancel_label "Cancel" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
	db_transaction {
            foreach group_id $group_ids {
                foreach party_id $party_ids {
                    # relation_add verifies that they aren't already in the group
                    switch [contact::type -party_id $party_id] {
                        person - user {
                            set rel_type "membership_rel"
                        }
                        organization {
                            set rel_type "organization_rel"
                        }
                    }
                    relation_add -member_state "approved" $rel_type $group_id $party_id
                }
            }
	}
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


