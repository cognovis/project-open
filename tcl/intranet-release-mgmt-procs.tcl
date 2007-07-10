# /packages/intranet-release-mgmt/tcl/intranet-release-mgmt.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Library for ]po[ specific release-mgmt functionality
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_release_mgmt_id {} {
    Returns the package id of the intranet-release-mgmt module
} {
    return [util_memoize "im_package_release_mgmt_id_helper"]
}

ad_proc -private im_package_release_mgmt_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-release-mgmt'
    } -default 0]
}


# ----------------------------------------------------------------------
# Release Stati
# ---------------------------------------------------------------------

# 4500-4599    (reserved)

ad_proc -public im_release_mgmt_status_developing {} { return 4500 }
ad_proc -public im_release_mgmt_status_read_to_build {} { return 4540 }
ad_proc -public im_release_mgmt_status_build {} { return 4550 }
ad_proc -public im_release_mgmt_status_ready_for_integration_test { } { return 4560 }
ad_proc -public im_release_mgmt_status_ready_for_acceptance_test { } { return 4570 }
ad_proc -public im_release_mgmt_status_approved {} { return 4585 }
ad_proc -public im_release_mgmt_status_accepted {} { return 4590 }
ad_proc -public im_release_mgmt_status_closed {} { return 4595 }


ad_proc -public im_release_mgmt_status_default {} { return 4500 }


# ----------------------------------------------------------------------
# Release-Mgmt Components
# ---------------------------------------------------------------------

ad_proc -public im_release_mgmt_project_component {
    -project_id
    -return_url
} {
    Returns a list release items associated to the current project
} {
    # Is this a "Software Release" Project
    set release_category [parameter::get -package_id [im_package_ganttproject_id] -parameter "ReleaseProjectType" -default "Software Release"]
    if {![im_project_has_type $project_id $release_category]} { return "" }

    set params [list \
	[list project_id $project_id] \
	[list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-release-mgmt/www/view-list-display"]
    return $result
}



# ----------------------------------------------------------------------
# Journal component for Release Management
# ---------------------------------------------------------------------


ad_proc -public im_release_mgmt_journal_component {
    -project_id:required
    -return_url
} {
    Show the Journal for the current project
} {
    # Is this a "Software Release" Project
    set release_category [parameter::get -package_id [im_package_ganttproject_id] -parameter "ReleaseProjectType" -default "Software Release"]
    if {![im_project_has_type $project_id $release_category]} { return "" }

    set params [list [list object_id $project_id]]
    set result [ad_parse_template -params $params "/packages/intranet-release-mgmt/www/journal"]
    return $result
}


ad_proc -public im_release_mgmt_new_journal {
    -object_id:required
    -action:required
    -action_pretty:required
    -message:required
} {
    Creates a new journal entry that can be passed to PL/SQL routines
} {
    set user_id [ad_get_user_id]
    set peer_ip [ad_conn peeraddr]

    set jid [db_string new_journal "
        select journal_entry__new (
                null,
                :object_id,
                :action,
                :action_pretty,
                now(),
                :user_id,
                :peer_ip,
                :message
        )
    "]
    return $jid
}
