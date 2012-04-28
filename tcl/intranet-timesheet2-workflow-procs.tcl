# /packages/intranet-timesheet2-workflow/tcl/intranet-timesheet-workflow-procs.tcl
#
# Copyright (C) 1998-2007 ]project-open[
# All rights reserved

ad_library {
    Definitions for the intranet timesheet workflow
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_conf_obj_type_default {} { return 17100 }

ad_proc -public im_timesheet_conf_obj_status_requested {} { return 17000 }
ad_proc -public im_timesheet_conf_obj_status_active {} { return 17010 }
ad_proc -public im_timesheet_conf_obj_status_rejected {} { return 17020 }
ad_proc -public im_timesheet_conf_obj_status_deleted {} { return 17090 }



# ---------------------------------------------------------------------
# Create a new workflow after logging hours
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_workflow_spawn_update_workflow {
    -project_id:required
    -user_id:required
    -start_date:required
    -end_date:required
    {-workflow_key "timesheet_approval_workflow_wf" }
} {
    Check if there is already a WF running for that project/user/date
    and either reset this WF or create a new one if there wasn't one before.
    @return case_id
    @param julian_date: The date of hour logging (single day) or the 
           start date of the hour logging (should be the Monday of the week)

    @author frank.bergmann@project-open.com
} {
    set result_html ""

    # ---------------------------------------------------------------
    # Setup & Defaults

    set wf_user_id $user_id
    set user_id [ad_maybe_redirect_for_registration]

    # ---------------------------------------------------------------
    # Check if the conf_object already exists

    set conf_object_ids [db_list conf_objects "
	select	co.conf_id
	from	im_timesheet_conf_objects co
	where	conf_project_id = :project_id and
		conf_user_id = :wf_user_id and
		start_date = :start_date
    "]
    ns_log Notice "spawn_update_workflow: conf_object_ids = $conf_object_ids"

    # ---------------------------------------------------------------
    # Create a new Timesheet Confirmation Object if not there

	    set conf_object_id [im_timesheet_conf_object_new \
		  -project_id $project_id \
		  -user_id $wf_user_id \
		  -start_date $start_date \
		  -end_date $end_date \
            ]

	    # Mark all hours in the included conf_obj as included
	    db_dml update_hours "
		update	im_hours
		set	conf_object_id = :conf_object_id
		from	(
		    	select	h.*
			from	im_hours h,
				im_projects p,
				im_projects main_p
			where
				h.project_id = p.project_id and
				main_p.project_id = :project_id and
				p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
				h.day >= :start_date and
				h.day <= :end_date and
				h.user_id = :wf_user_id
			) h
		where
			im_hours.day = h.day and
			im_hours.user_id = h.user_id and
			im_hours.project_id = h.project_id
	    "


set ttt {
    switch [llength $conf_object_ids] {
	0 {	   
	    append result_html "<li>No previous confirmation object found - Creating new confirmation object.\n"
	}
	1 {
	    set conf_object_id [lindex $conf_object_ids 0]
	    append result_html "<li>Confirmation object already exists: #$conf_object_id\n"
	}
	default {
	    ad_return_complaint 1 "<b>Internal Error: Too many confirmation objects</b>:
	    	We have found more the one confirmation object ($conf_object_ids)
		for the given project_id=$project_id, user_id=$user_id and start_date=$start_date.
		Please inform your System Administrator.
	    "
	    ad_script_abort
	}
    }
}

    # ---------------------------------------------------------------
    # Check if the WF-Key is valid

    set wf_valid_p [db_string wf_valid_check "
	select count(*)
	from acs_object_types
	where object_type = :workflow_key
    "]
    if {!$wf_valid_p} {
	ad_return_complaint 1 "Workflow '$workflow_key' does not exist"
	ad_script_abort
    }

    # ---------------------------------------------------------------
    # Determine the case for the conf_object or create it.

    set context_key ""
    set case_ids [db_list case "
    	select	case_id
	from	wf_cases
	where	object_id = :conf_object_id
    "]
    ns_log Notice "spawn_update_workflow: case_ids = $case_ids"

    if {[llength $case_ids] == 0} {

	set case_id [wf_case_new \
		$workflow_key \
		$context_key \
		$conf_object_id
        ]
	ns_log Notice "spawn_update_workflow: case_id = $case_id"
#	append result_html "<li>No workflow found - creating new one #$case_id\n"

	# Skip the first transition of the WF - "Modify"
	im_workflow_skip_first_transition -case_id $case_id

	# Set the default value for "sign_off_ok" to "t"
	set attrib "confirm_hours_are_the_logged_hours_ok_p"
	db_string set_attribute_value "select acs_object__set_attribute (:case_id,:attrib,'t')"

    } else {
        set case_id [lindex $case_ids 0]
	append result_html "<li>Workflow already exists: #$case_id\n"

    }

    append result_html "<br>&nbsp;<br>\n"
    return $result_html
#    return $case_id
}


# ---------------------------------------------------------------------
# Create TS Confirmation Object
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_conf_object_new {
    -project_id
    -user_id
    -start_date
    -end_date
    {-conf_status_id 0}
    {-conf_type_id 0}
} {
    Create a new confirmation object
} {
    if {0 == $conf_status_id} { set conf_status_id [im_timesheet_conf_obj_status_active] }
    if {0 == $conf_type_id} { set conf_type_id [im_timesheet_conf_obj_type_default] }

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
        set conf_oid [db_string create_conf_object "
	    select im_timesheet_conf_object__new (
		null,
		'im_timesheet_conf_object',
		now(),
		[ad_get_user_id],
		'[ad_conn peeraddr]',
		null,

		:project_id,
		:user_id,
		:start_date,
		:end_date,
		:conf_type_id,
		:conf_status_id
	    );
        "]
    }
    return $conf_oid
}



ad_proc -public im_timesheet_conf_object_delete {
    -project_id
    -user_id
    -day_julian
} {
    Delete a confirmation object for the specified (main-) project
    that covers the specified day.
} {
    # Get the main project - the first project above or equal to project_id that is not a task.
    db_1row parent "
                select  project_id,
                        parent_id,
                        project_type_id
                from    im_projects
                where   project_id = :project_id
    "
    # Go up the hierarchy only if there is a parent_id != null...
    while {"" != $parent_id && $project_type_id == [im_project_type_task]} {
       db_1row parent "
                select  project_id,
                        parent_id,
                        project_type_id
                from    im_projects
                where   project_id = :parent_id
       "
    }
    set main_project_id $project_id


    # Check for ConfirmationObjects matching the conditions
    set conf_ids [db_list conf_ids "
		select distinct
			c.conf_id
		from
			im_timesheet_conf_objects c
		where
			c.conf_project_id = :main_project_id and
			c.conf_user_id = :user_id and
			to_date(:day_julian, 'J') between c.start_date and c.end_date
    "]

    # Delete the conf_objects
    set ctr 0
    foreach conf_id $conf_ids {
	db_string conf_delete "select im_timesheet_conf_object__delete(:conf_id)"
	incr ctr
    }
    return $ctr
}



# ---------------------------------------------------------------------
# Timesheet Confirmation Object - Workflow Permissions
#
# ---------------------------------------------------------------------

ad_proc im_timesheet_conf_new_page_wf_perm_table { } {
    Returns a hash array representing (role x status) -> (v r d w a),
    controlling the read and write permissions on the Timesheet Conf 
    Object's new page, depending on the users's role and the WF status.
} {
    set req [im_timesheet_conf_obj_status_requested]
    set rej [im_timesheet_conf_obj_status_rejected]
    set act [im_timesheet_conf_obj_status_active]
    set del [im_timesheet_conf_obj_status_deleted]

    set perm_hash(owner-$rej) {v r d}
    set perm_hash(owner-$req) {v r d}
    set perm_hash(owner-$act) {v r d}
    set perm_hash(owner-$del) {v r d}

    set perm_hash(assignee-$rej) {v r}
    set perm_hash(assignee-$req) {v r}
    set perm_hash(assignee-$act) {v r}
    set perm_hash(assignee-$del) {v r}

    set perm_hash(hr-$rej) {v r d w a}
    set perm_hash(hr-$req) {v r d w a}
    set perm_hash(hr-$act) {v r d w a}
    set perm_hash(hr-$del) {v r d w a}

    return [array get perm_hash]
}



ad_proc im_timesheet_conf_new_page_wf_perm_delete_button {
    -conf_id:required
} {
    Should we show the "Delete" button in the TimesheetConfNewPage?
    The button is visible only for the Owner of the timesheet
    and the Admin, but nobody else during the course of the WF.
} {
    set perm_table [im_timesheet_conf_new_page_wf_perm_table]
    set perm_set [im_workflow_object_permissions \
		    -object_id $conf_id \
		    -perm_table $perm_table
    ]

    ns_log Notice "im_timesheet_conf_new_page_wf_perm_delete_button conf_id=$conf_id => $perm_set"
    return [expr [lsearch $perm_set "d"] > -1]
}

ad_proc im_timesheet_conf_new_page_wf_perm_edit_button {
    -conf_id:required
} {
    Should we show the "Edit" button in the TimesheetConfNewPage?
} {
    set perm_table [im_timesheet_conf_new_page_wf_perm_table]
    set perm_set [im_workflow_object_permissions \
		    -object_id $conf_id \
		    -perm_table $perm_table
    ]

    ns_log Notice "im_timesheet_conf_new_page_wf_perm_edit_button conf_id=$conf_id => $perm_set"
    return [expr [lsearch $perm_set "w"] > -1]
}


ad_proc eval_wf_start_date {
    date_julian
    day_of_week
} {
    Helper routine to evaluate start for each week in TS calendar view for Weekly TS confirmation
} {

    set date_ansi [dt_julian_to_ansi $date_julian]

    #Current month
    set date_part_month [clock format [clock scan $date_ansi] -format %m]

    #Current year
    set date_part_year [clock format [clock scan $date_ansi] -format %Y]

    # If we count seven days back, are we still in the same month?
    set one_week_back_month [clock format [clock scan {-7 days} -base [clock scan $date_ansi] ] -format %m]

    if { $one_week_back_month == $date_part_month } {
       # Find
        return [expr $date_julian - [expr $day_of_week - 1]]
    } else {
        # return first day of month
        return [dt_ansi_to_julian_single_arg "$date_part_year-$date_part_month-01"]
    }
}
