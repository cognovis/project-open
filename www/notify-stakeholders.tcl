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
    { tid:integer,multiple 0 }
    action_id:integer
    return_url
}


# --------------------------------------------------------
# Defaults & Permission
# --------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

set action_name [im_category_from_id $action_id]
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

foreach ticket_id $tid {
    im_ticket_permissions $current_user_id $ticket_id view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}

# Make sure an empty list of tickets won't cause an error further down.
lappend tid -1

# --------------------------------------------------------
# Determine Stakeholders
# --------------------------------------------------------

set stakeholder_sql "
		-- customer contacts of the tickets
		select	ticket_customer_contact_id as user_id
		from	im_tickets t
		where	 t.ticket_id in ([join $tid ","])
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
set stakeholders [db_list stakeholders $stakeholder_sql]

set url [export_vars -base "/intranet-contacts/message" {return_url}]
foreach user_id $stakeholders {
    append url "&to=$user_id"
}

ad_returnredirect $url

set ttt {

    {attachment_id:integer,multiple,optional}
    {object_id:integer,multiple,optional}
    {party_id:multiple,optional}
    {party_ids ""}
    {search_id:integer ""}
    {message_type ""}
    {message:optional}
    {header_id:integer ""}
    {footer_id:integer ""}
    {return_url "./"}
    {file_ids ""}
    {files_extend:integer,multiple,optional ""}
    {item_id:integer ""}
    {folder_id:integer ""}
    {signature_id:integer ""}
    {subject ""}
    {content_body:html ""}
    {to:integer,multiple,optional ""}
    {page:optional 1}
    {context_id:integer ""}
    {cc ""}
    {bcc ""}
}
