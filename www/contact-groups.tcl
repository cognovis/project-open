ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {return_url "./"}
}
contact::require_visiblity -party_id $party_id

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set recipients [list]

lappend recipients "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a>"

set recipients [join $recipients ", "]


set group_options [contact::groups -expand "all" -privilege_required "create"]

set groups_belonging_to [db_list get_party_groups { select group_id from group_distinct_member_map where member_id = :party_id }]

set groups_to_add [list [list "[_ intranet-contacts.--_select_a_group_--]" ""]]
foreach group $group_options {
    if { [lsearch "$groups_belonging_to" [lindex $group 1]] >= 0 } {
        # the party is part of this group
        lappend groups_in     [list [lindex $group 0] [lindex $group 1] [lindex $group 2]] 
    } else {
        lappend groups_to_add [list [lindex $group 0] [lindex $group 1]]
    }
}

if { [llength $group_options] == "0" } {
    ad_return_error "[_ intranet-contacts.lt_Insufficient_Permissi]" "[_ intranet-contacts.lt_You_do_not_have_permi]"
}

