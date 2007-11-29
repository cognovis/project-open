# /packages/intranet-timesheet2-workflow/www/new-workflow.tcl
#
# Copyright (C) 2003-2007 ]project-open[
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
set week_offset 1

set gregorian_day [db_string a "select to_date(:julian_date, 'J')"]
set week [db_string a "select to_char(:gregorian_day::date, 'WW')"]
set year [db_string a "select to_char(:gregorian_day::date, 'YYYY')"]

set start_date [db_string a "select to_date('$year-$week', 'YYYY-WW')::date - ${week_offset}::integer"]
set end_date [db_string a "select to_date('$year-[expr $week+1]', 'YYYY-WW')::date - 1 - ${week_offset}::integer"]

# ---------------------------------------------------------------
# Check if the object already exists and submit an error message
# ---------------------------------------------------------------

set conf_object_id [db_list exists "
	select	co.conf_id
	from	im_timesheet_conf_objects co
	where	conf_project_id = :project_id and
		conf_user_id = :wf_user_id and
		start_date = :start_date
"]

if {[llength $conf_object_id] > 0} {

    set conf_url [export_vars -base "/intranet-timesheet2-workflow/view" {conf_object_id}]
    ad_returnredirect $conf_url
    ad_script_abort

    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-timesheet2-workflow.Conf_Already_There "Timesheet Hours Confirmation already initiated"]</b>:<p>
	[lang::message::lookup "" intranet-timesheet2-workflow.Conf_Already_There_Message "
		You have already started a confirmation workflow for your hours <br>
		from $start_date to $end_date. <br>
		To check the status of your hours please see
		<a href=$conf_url>here</a>.
	"]
    "
    ad_script_abort
}


# ---------------------------------------------------------------
# Check if the WF-Key is valid
# ---------------------------------------------------------------

# Check that the workflow_key is available
set wf_valid_p [db_string wf_valid_check "
	select count(*)
	from acs_object_types
	where object_type = :workflow_key
"]

if {!$wf_valid_p} {
    ad_return_complaint 1 "Workflow '$workflow_key' does not exist"
    ad_script_abort
}

set context_key ""

# ---------------------------------------------------------------
# Create a new Timesheet Confirmation Object
# ---------------------------------------------------------------

if {0 == $project_id} {
	set project_list [db_list projects "
		select distinct
			project_id
		from	im_hours
		where	user_id = :user_id and
			day >= :start_date and
			day < :end_date
	"]
} else {
    set project_list [list $project_id]
}

foreach project_id $project_list {
    set conf_oid [im_timesheet_conf_object_new \
		  -project_id $project_id \
		  -user_id $wf_user_id \
		  -start_date $start_date \
		  -end_date $end_date \
    ]

    set case_id [wf_case_new \
		$workflow_key \
		$context_key \
		$conf_oid
    ]
}

ad_returnredirect $return_url

