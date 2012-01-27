# /packages/intranet-timesheet2-workflow/www/new-workflow.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Creates a new workflow for the associated hours
    @author frank.bergmann@project-open.com
} {
    user_id
    { return_url "/intranet-timesheet2-workflow/conf-objects/index" }
    { start_date_julian "" }
    { end_date_julian "" }
    { workflow_key "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set wf_user_id $user_id
set user_id [ad_maybe_redirect_for_registration]
set page_title "[lang::message::lookup "" intranet-timesheet2-workflow.Create_New_Timesheet_Workflow "New Timesheet Workflow(s)"]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set date_format_pretty "YYYY-MM-DD"
if { "" == $workflow_key } {
    set workflow_key [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2-workflow] -parameter "DefaultWorkflowKey" -default "timesheet_approval_wf"]
}

# ---------------------------------------------------------------
# Create new Timesheet Confirmation Objects and their WFs
# ---------------------------------------------------------------

# Get all hours for the current user in the last week and check
# whether the hours are logged on a task or on a project.
# If it's a task then search the parent_id hierarchy for the next
# "real" project.

set start_date [db_string start_date "select to_date(:start_date_julian, 'J')"]
set end_date [db_string start_date "select to_date(:end_date_julian, 'J')"]

set hours_sql "
	select	h.project_id,
		p.project_type_id,
		p.parent_id
	from	im_hours h,
		im_projects p
	where	h.conf_object_id is null and
		h.user_id = :wf_user_id and
		h.day >= :start_date and
		h.day <= :end_date and
		h.project_id = p.project_id
"

set hours_list [list]
db_foreach hours $hours_sql {
    # Go up the hierarchy only if there is a parent_id != null...
    while {"" != $parent_id && $project_type_id == [im_project_type_task]} {
       db_1row parent "
       	       	select	project_id,
			parent_id,
	       		project_type_id
		from	im_projects
		where	project_id = :parent_id
       "
    }
    # Us a hash in order to eliminate duplicates
    set project_list_hash($project_id) $project_id
}

set project_list [array names project_list_hash]


set li_html ""
foreach project_id $project_list {

    set project_name [util_memoize "db_string pname \"select project_name from im_projects where project_id=$project_id\" -default {Error}"]
    append li_html "<li>[lang::message::lookup "" intranet-timesheet2-workflow.Starting_WF_for_project "
    	   Starting a new workflow for project '%project_name%' (#%project_id%).
    "]\n"

    set debug_html [im_timesheet_workflow_spawn_update_workflow \
	-project_id $project_id \
	-user_id $wf_user_id \
	-start_date $start_date \
	-end_date $end_date \
	-workflow_key $workflow_key \
    ]
    append li_html "<ul>\n$debug_html\n</ul>\n"

}

if {0 == [llength $project_list]} { 
    append li_html "<li>No projects found for hours.\n"
}
