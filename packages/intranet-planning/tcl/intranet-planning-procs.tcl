# /packages/intranet-planning/tcl/intranet-planning-procs.tcl
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

ad_proc -public im_planning_item_status_active {} { return 73000 }
ad_proc -public im_planning_item_status_deleted {} { return 73102 }

ad_proc -public im_planning_item_type_revenues {} { return 73100 }
ad_proc -public im_planning_item_type_costs {} { return 73102 }


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_planning_component {
    {-planning_type_id 73100 }
    {-planning_time_dim_id 73202 }
    {-planning_dim1_id "" }
    {-planning_dim2_id "" }
    {-planning_dim3_id "" }
    {-restrict_to_main_project_p 1 }
    -object_id
} {
    Returns a HTML component to show all object related planning items.
    Default values indicate type "Revenue" planning by time dimension "Month".
    No planning dimensions are specified by default, so that means planning
    per project and sub-project normally.
} {
    # Skip evaluating the component if we are not in a main project
    set parent_id [util_memoize [list db_string parent "select parent_id from im_projects where project_id = $object_id" -default ""]]
    if {$restrict_to_main_project_p && "" != $parent_id} { return "" }

    set params [list \
		    [list object_id $object_id] \
		    [list planning_type_id $planning_type_id] \
		    [list planning_time_dim_id $planning_time_dim_id] \
		    [list planning_dim1_id $planning_dim1_id] \
		    [list planning_dim2_id $planning_dim2_id] \
		    [list planning_dim3_id $planning_dim3_id] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-planning/lib/planning-component"]
    return [string trim $result]
}

