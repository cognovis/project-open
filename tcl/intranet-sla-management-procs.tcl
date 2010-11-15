# /packages/intranet-sla-management/tcl/intranet-sla-management-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_sla_parameter_status_active {} { return 72000 }
ad_proc -public im_sla_parameter_status_deleted {} { return 72002 }

ad_proc -public im_sla_parameter_type_default {} { return 72100 }


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_sla_parameter_component {
    -object_id
} {
    Returns a HTML component to show a list of SLA parameters with the option
    to add more parameters
} {
    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/sla-parameters-list-component"]
    return [string trim $result]
}


ad_proc -public im_sla_parameter_list_component {
    {-project_id ""}
    {-param_id ""}
} {
    Returns a HTML component with a mix of SLA parameters and indicators.
    The component can be used both on the SLAViewPage and the ParamViewPage.
} {
    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list project_id $project_id] \
		    [list param_id $param_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/indicator-component"]
    return [string trim $result]
}

