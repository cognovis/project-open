# /packages/intranet-sla-management/www/ticket-priority-component.tcl
#
# Copyright (c) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#
# Shows Ticket Priority tuples for the specified SLA.

# ---------------------------------------------------------------
# Variables
# ---------------------------------------------------------------

#    { project_id:integer "" }
#    return_url 

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {"" == $return_url} { set return_url [im_url_with_query] }
set page_title [lang::message::lookup "" intranet-sla-management.Ticket_Priority "Ticket Priority"]
set context_bar [im_context_bar $page_title]
set context ""
set sla_id $project_id

im_project_permissions $current_user_id $project_id sla_view sla_read sla_write sla_admin
# sla_read checked in the .adp file

set create_new_entry_msg [lang::message::lookup "" intranet-sla-management.Create_new_entry "Create a new mapping entry"]


# ---------------------------------------------------------------
# Read the priority map from DB
# The map contains triples of (id, ticket_type_id, ticket_severity_id => ticket_priority_id)

set priority_map_sql "
	select	sla_ticket_priority_map
	from	im_projects
	where	project_id = :project_id
"
set priority_map [db_string priority_map $priority_map_sql -default ""]




# ----------------------------------------------------
# Create the list of all tuples

set elements {
	rfq_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" \
		  onclick=\"acs_ListCheckAll('map_list', this.checked)\" \
		  title=\"Check/uncheck all rows\">"
	    display_template {
		@map_lines.map_chk;noquote@
	    }
	}
	ticket_type {	
	    label "[lang::message::lookup {} intranet-sla-management.Ticket_Type {Type}]"
	}
	ticket_severity {	
	    label "[lang::message::lookup {} intranet-sla-management.Ticket_Type {Severity}]"
	}
	ticket_priority {	
	    label "[lang::message::lookup {} intranet-sla-management.Ticket_Priority {Prio}]"
	}
}


# -------------------------------------------------------------
# Define the list view

set actions_list [list]
set bulk_actions_list [list]

if {$sla_write} {
#     set new_msg [lang::message::lookup "" intranet-sla-management.New_Entry "New Entry"]
#     lappend actions_list $new_msg [export_vars -base "/intranet-sla-management/ticket-priority-new" {return_url project_id}] $new_msg

    set delete_msg [lang::message::lookup "" intranet-sla-management.Delete_Entry "Delete Entry"]
    lappend bulk_actions_list $delete_msg "/intranet-sla-management/ticket-priority-del" $delete_msg
}

set export_var_list [list object_id return_url]
set list_id "map_list"

template::list::create \
    -name $list_id \
    -multirow map_lines \
    -key map_id \
    -has_checkboxes \
    -actions $actions_list \
    -bulk_action_method GET \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	project_id
	return_url
    } \
    -bulk_action_method POST \
    -row_pretty_plural "[lang::message::lookup {} intranet-sla-management.SLA_Mapeters {SLA mapeters}]" \
    -elements $elements

# ----------------------------------------------------
# Create a "multirow" to show the results
#
set extend_list {map_chk map_url}

multirow create map_lines map_id map_chk ticket_type_id ticket_type ticket_severity_id ticket_severity ticket_priority_id ticket_priority

foreach tuple $priority_map {
    set map_id [lindex $tuple 0]
    set type_id [lindex $tuple 1]
    set severity_id [lindex $tuple 2]
    set prio_id [lindex $tuple 3]

    set type [im_category_from_id $type_id]
    set severity [im_category_from_id $severity_id]
    set prio [im_category_from_id $prio_id]

    set map_chk "<input type=checkbox name=map_ids value=$map_id id='map_list,$map_id'>"
    set map_url [export_vars -base "/intranet-sla-management/ticket_priority-new" {{form_mode display} project_id map_id}]

    multirow append map_lines $map_id $map_chk $type_id $type $severity_id $severity $prio_id $prio
}

