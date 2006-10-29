# /packages/intranet-bug-tracker/tcl/intranet-bug-tracker.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    This Bug-Tracker integration aloows to associate ]po[ tasks
    with OpenACS Bug-Tracker tickets, allowing for the best of
    the two worlds
	- Developer friendly maintenance of product bugs
	- Multiple "Products"
	- A customer wizard to create new bugs and to check his
	  own bugs, but without being able to see the bugs of
	  other customers
	- Integration with Timesheet Billing using the billing
	  wizard.

    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_project_type_bt_container { } { return 4300 }
ad_proc -public im_project_type_bt_task { } { return 4305 }



# ----------------------------------------------------------------------
# Package ID
# ----------------------------------------------------------------------


ad_proc -public im_package_bug_tracker_id {} {
    Returns the package id of the intranet-bug-tracker module
} {
    return [util_memoize "im_package_bug_tracker_id_helper"]
}

ad_proc -private im_package_bug_tracker_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-bug-tracker'
    } -default 0]
}


# ----------------------------------------------------------------------
# Components
# ----------------------------------------------------------------------

ad_proc -public im_bug_tracker_container_component {

} {
    Returns a HTML widget for a BT "Container Project" to allow
    the PM to set BT parameters like the BT project (better: "Product")
    and the current version, so that the customer doesn't need to set
    all these variables.
} {
    return ""




}

