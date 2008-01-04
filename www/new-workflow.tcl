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
    { return_url "/intranet-timesheet2-workflow/index" }
    { julian_date "" }
    { project_id 0}
    { workflow_key "timesheet_approval_workflow_wf" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set wf_user_id $user_id

set user_id [ad_maybe_redirect_for_registration]
set page_title "[lang::message::lookup "" intranet-timesheet2-workflow.Create_New_Timesheet_Workflow "Create New Timesheet Workflow"]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

# ---------------------------------------------------------------
# Find out the Gregorian start_date and end_date for the given
# Julian date
# ---------------------------------------------------------------

# When does the week start? On Sunday here in ]po[...
set week_offset 0

set gregorian_day [db_string a "select to_date(:julian_date, 'J')"]
set week [db_string a "select to_char(:gregorian_day::date, 'WW')"]
set year [db_string a "select to_char(:gregorian_day::date, 'YYYY')"]
set start_date [db_string a "select to_date('$year-$week', 'YYYY-WW')::date - ${week_offset}::integer"]
set end_date [db_string a "select to_date('$year-[expr $week+1]', 'YYYY-WW')::date - 1 - ${week_offset}::integer"]


#ad_return_complaint 1 "$gregorian_day, $week, $year, $start_date, $end_date"

# ---------------------------------------------------------------
# Create new Timesheet Confirmation Objects and their WFs
# ---------------------------------------------------------------

if {0 == $project_id} {
	set project_list [db_list projects "
		select distinct
			main_p.project_id
		from
			im_hours h,
			im_projects p,
			im_projects main_p
		where
			h.project_id = p.project_id and
			h.user_id = :wf_user_id and
			h.day >= :start_date and
			h.day < :end_date and
			tree_root_key(p.tree_sortkey) = main_p.tree_sortkey
	"]
} else {
    set project_list [list $project_id]
}

foreach project_id $project_list {

    im_timesheet_workflow_spawn_update_workflow \
	-project_id $project_id \
	-user_id $wf_user_id \
	-start_date $start_date \
	-end_date $end_date \
	-workflow_key "timesheet_approval_workflow_wf"

}

ad_returnredirect $return_url
