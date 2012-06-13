# /packages/intranet-calendar/tcl/intranet-calendar.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Library for ]po[ specific calendar functionality
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_calendar_id {} {
    Returns the package id of the intranet-calendar module
} {
    return [util_memoize "im_package_calendar_id_helper"]
}

ad_proc -private im_package_calendar_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-calendar'
    } -default 0]
}


ad_proc -public package_calendar_id {} {
    Returns the package id of the calendar module
} {
    return [util_memoize "db_string cal \"select package_id from apm_packages where package_key = 'calendar'\" -default 0"]
}





# ----------------------------------------------------------------------
# Calendar Components
# ---------------------------------------------------------------------


ad_proc -public im_calendar_home_component {
    { -skip 0 }
} {
    Returns the package id of the intranet-calendar module
} {
    set today ""
    set current_user_id [ad_get_user_id]
    set cal_package_id [util_memoize [list db_string cal_package "select package_id from apm_packages where package_key = 'calendar'" -default 0]]
    set perm_p [permission::permission_p -party_id $current_user_id -object_id $cal_package_id -privilege "read"]
    if {!$perm_p} { return "" }

    catch {set today [ns_set iget [ad_conn form] "date"]} err
    if {"" == $today} {
	set today [lindex [split [ns_localsqltimestamp] " "] 0]
    }
    set package_id [package_calendar_id]
    set params [list \
	[list base_url "/calendar/"] \
	[list date $today] \
	[list package_id $package_id] \
	[list show_calendar_name_p 0] \
	[list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/calendar/www/view-week-display"]
    return $result
}
