
# /packages/intranet-sharepoint/tcl/intranet-sharepoint-procs.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_sharepoint_project_component {
    -project_id
} {
    Returns a HTML component to show an iFrame pointing to a Sharepoint site
} {
    set params [list \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sharepoint/www/sharepoint-iframe-component"]
    return [string trim $result]
}
