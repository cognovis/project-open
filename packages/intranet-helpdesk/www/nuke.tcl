# /packages/intranet-helpdesk/www/nuke.tcl
#
# Copyright (C) 1998-2008 ]project-open[

ad_page_contract {
    Remove a ticket completely
    @author frank.bergmann@project-open.com
} {
    ticket_id:integer,notnull
    { return_url "/intranet-helpdesk/" }
}

db_1row user_full_name "
    select
	*,
	p.project_name as ticket_name
    from
	im_tickets t,
	im_projects p
    where 
	t.ticket_id = :ticket_id and
	p.project_id = t.ticket_id
"

set page_title [lang::message::lookup "" intranet-helpdesk.Nuke_this_ticket "Nuke this ticket"]
set context_bar [im_context_bar [list /intranet/projects/ "[lang::message::lookup "" intranet-helpdesk.Helpdesk "Helpdesk"]"] $page_title]
set object_name $project_name
set object_type "ticket"

