# /packages/intranet-helpdesk/www/notifiy-stakeholders.tcl
#
# Copyright (c) 2010 ]project-open[
# All rights reserved

ad_page_contract {
    Notify everybody related to a number of tickets.
    The difficulty is that we're dealing with multiple tickets possibly.
    
    @param tid: A list of ticket_ids 
    @param action_id: A category indicating the original action.
           Example: "Close & Notify"
    @return_url: Where to go after we've sent out the messages

    @author frank.bergmann@project-open.com
} {
    { tid 0 }
    action_id:integer
    return_url
}


# --------------------------------------------------------
# Defaults & Permission
# --------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Notify_Stakeholders "Notify Stakeholders"]
set context_bar [im_context_bar $page_title]

# Get the SystemUrl without trailing "/"
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url [expr $sysurl_len-1] $sysurl_len]
if {[string equal "/" $last_char]} {
    set system_url "[string range $system_url 0 [expr $sysurl_len-2]]"
}

set action_name [im_category_from_id $action_id]
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

foreach ticket_id $tid {
    im_ticket_permissions $current_user_id $ticket_id view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}

# Make sure an empty list of tickets won't cause an error further down.
lappend tid -1

set ticket_sql "
	select	t.*,
		p.*
	from	im_tickets t,
		im_projects p
	where 	t.ticket_id = p.project_id and
		t.ticket_id in ([join $tid ","])
"
set ticket_nr_list {}
set ticket_count 0
set ticket_name ""
set ticket_url_list {}
db_foreach tickets $ticket_sql {
    lappend ticket_nr_list "#$project_nr"
    set ticket_name $project_nr
    lappend ticket_url_list "- [export_vars -base "$system_url/intranet-helpdesk/new" {{form_mode display} ticket_id}]"
    incr ticket_count
}

set subject "undefined"
switch $action_id {
    30500 { set action_verb "Closed" }
    30510 { set action_verb "Closed" }
    30515 { set action_verb "Frozen" }
    30520 { set action_verb "Duplicated" }
    30530 { set action_verb "Opened" }
    30532 { set action_verb "Opened" }
    30540 { set action_verb "Associated" }
    30550 { set action_verb "Escalated" }
    30552 { set action_verb "Closed" }
    30560 { set action_verb "Resolved" }
    30590 { set action_verb "Deleted" }
    30599 { set action_verb "Nuked" }
    default {
	ad_return_complaint 1 "Unknown action_id '$action_id'"
    }
}

set action_verb_l10n [lang::message::lookup "" intranet-helpdesk.Action_verb_$action_verb $action_verb]
set action_verb_lower [string tolower $action_verb]

if {$ticket_count <= 1} {
    set subject "$action_verb_l10n ticket: $ticket_name"
} else {
    set subject "$action_verb_l10n tickets: [join $ticket_nr_list ", "]"
}



set ticket_urls [join $ticket_url_list "\n"]

set message [lang::message::lookup "" intranet-helpdesk.${action_verb}_ticket_msg "
Dear {first_names},

We have $action_verb_lower the following ticket(s):
%ticket_urls%

Best regards
{sender_first_names}
"]



# --------------------------------------------------------
# Determine Stakeholders
# --------------------------------------------------------


set bulk_action_list {}
# lappend bulk_actions_list "[lang::message::lookup "" intranet-helpdesk.Delete "Delete"]" "associate-delete" "[lang::message::lookup "" intranet-helpdesk.Remove_checked_items "Remove Checked Items"]"

set actions [list]
# set assoc_msg [lang::message::lookup {} intranet-helpdesk.New_Association {Associated with new Object}]
# lappend actions $assoc_msg [export_vars -base "/intranet-helpdesk/associate" {return_url {tid $ticket_id}}] ""

set stakeholder_inner_sql "
		-- customer contacts of the tickets
		select	ticket_customer_contact_id as user_id
		from	im_tickets t
		where	t.ticket_id in ([join $tid ","])
		UNION
		-- direct members of the tickets
		select	u.user_id
		from	acs_rels r,
			im_tickets t,
			users u
		where	r.object_id_one = u.user_id and
			r.object_id_two = t.ticket_id and
			t.ticket_id in ([join $tid ","])
		UNION
		-- authors of the forum topics related to the tickets
		select	ft.owner_id as user_id
		from	im_forum_topics ft
		where	ft.object_id in ([join $tid ","])
"

set stakeholder_sql "
	select	*
	from	(
		select	s.user_id,
			im_email_from_user_id(s.user_id) as email,
			im_name_from_user_id(s.user_id) as user_name
		from	($stakeholder_inner_sql) s
	UNION
		select	note_id as user_id,
			n.note as email,
			n.note as user_name
		from	($stakeholder_inner_sql) s,
			im_notes n
		where	s.user_id = n.object_id and
			n.note_type_id = [im_note_type_email]
		) u
	where
		user_id != 0
	order by
		user_name
"
db_multirow -extend { stakeholder_chk stakeholder_url checked } stakeholders stakeholders $stakeholder_sql {
    set stakeholder_url [export_vars -base "/intranet/users/view" {user_id}]
    set stakeholder_chk "<input type=\"checkbox\"
                                name=\"stakeholder_id\"
                                value=\"$user_id\"
                                id=\"stakeholders_list,$user_id\">
    "
    set checked "checked"
}



set send_msg [lang::message::lookup "" intranet-helpdesk.Send "Send"]


