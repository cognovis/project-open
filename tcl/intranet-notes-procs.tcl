# /packages/intranet-notes/tcl/intranet-notes-procs.tcl
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

ad_proc -public im_note_status_active {} { return 11400 }
ad_proc -public im_note_status_deleted {} { return 11402 }


# ----------------------------------------------------------------------
# PackageID
# ----------------------------------------------------------------------

ad_proc -public im_package_notes_id {} {
    Returns the package id of the intranet-notes module
} {
    return [util_memoize "im_package_notes_id_helper"]
}

ad_proc -private im_package_notes_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-notes'
    } -default 0]
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_notes_project_component {
    -object_id
} {
    Returns a HTML component to show all project related notes
} {
    set params [list \
		    [list base_url "/intranet-notes/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-notes/www/notes-list-component"]
    return $result
}
