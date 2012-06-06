# /packages/intranet-sla-management/www/ticket-priority-add.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Add a new tuple to the priority map at the SLA
} {
    project_id:integer
    ticket_type_id:integer
    ticket_severity_id:integer
    ticket_prio_id:integer
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set sla_id $project_id

im_project_permissions $current_user_id $project_id sla_view sla_read sla_write sla_admin
if {!$sla_write} {
    ad_return_complaint 1 "You don't have sufficient permission to perform this action"
    ad_script_abort
}

# ---------------------------------------------------------------
# Get the old map

set priority_map_sql "
        select  sla_ticket_priority_map
        from    im_projects
        where   project_id = :project_id
"
set priority_map [db_string priority_map $priority_map_sql -default ""]



# ---------------------------------------------------------------
# Add the new entry

set map_id [db_nextval im_ticket_priority_map_seq]
lappend priority_map [list $map_id $ticket_type_id $ticket_severity_id $ticket_prio_id]


# ---------------------------------------------------------------
# Write the updated map to the SLA

db_dml update_priority_map "
	update im_projects
	set sla_ticket_priority_map = :priority_map
	where project_id = :project_id
"

ad_returnredirect $return_url


