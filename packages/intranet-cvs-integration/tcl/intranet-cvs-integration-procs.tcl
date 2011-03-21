# /packages/intranet-cvs-integration/tcl/intranet-cvs-integration-procs.tcl
#
# Copyright (C) 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_cvs_log_component {
    {-return_url "" }
    {-object_id 0 }
    {-conf_item_id 0 }
} {
    Returns a HTML component to show all project related cvs logs
} {
    if {"" == $return_url} { set return_url [im_url_with_query] }
    set params [list \
		    [list base_url "/intranet-cvs-integration/"] \
		    [list object_id $object_id] \
		    [list conf_item_id $conf_item_id] \
		    [list return_url $return_url] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-cvs-integration/www/cvs-log-list-component"]
    return [string trim $result]
}
