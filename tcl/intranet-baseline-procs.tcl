# /packages/intranet-baseline/tcl/intranet-baseline-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_baseline_status_active {} { return 71000 }
ad_proc -public im_baseline_status_deleted {} { return 71002 }
ad_proc -public im_baseline_status_requested {} { return 71004 }
ad_proc -public im_baseline_status_rejected {} { return 71006 }

ad_proc -public im_baseline_type_default {} { return 71100 }


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_baseline_component {
    -project_id
} {
    Returns a HTML component to show all baselines related to a project
} {
    # Make sure project_id is an integer...
    im_security_alert_check_integer -location "im_baseline_component" -value $project_id

    set parent_id [util_memoize [list db_string parent "select parent_id from im_projects where project_id = $project_id" -default ""]]
    if {"" != $parent_id} { 
	# Shows this component only to main projects
	return "" 
    }
    set params [list \
		    [list base_url "/intranet-baseline/"] \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-baseline/www/baseline-list-component"]
    return [string trim $result]
}





ad_proc -public im_baseline_budget_comparison_component {
    -baseline_id
} {
    Returns a HTML component with a comparison of the
    baseline's budget vs. the current project's budget
} {
    # Make sure baseline_id is an integer...
    im_security_alert_check_integer -location "im_baseline_budgeet_comparison_component" -value $baseline_id
    set params [list \
		    [list baseline_id $baseline_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-baseline/lib/baseline-budget-comparison"]
    return [string trim $result]
}

