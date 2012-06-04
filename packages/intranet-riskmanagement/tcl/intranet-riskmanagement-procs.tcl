# /packages/intranet-riskmanagement/tcl/intranet-riskmanagement-procs.tcl
#
# Copyright (C) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Procs used in riskmanagement module

    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_risk_project_component {
    -project_id
} {
    Returns a HTML component to show all project related risks
} {
    set params [list [list project_id $project_id]]
#    set project_type_id [db_string ptype "select project_type_id from im_projects where project_id = :project_id" -default ""]
    set result [ad_parse_template -params $params "/packages/intranet-riskmanagement/lib/risk-project-component"]
    return [string trim $result]
}
