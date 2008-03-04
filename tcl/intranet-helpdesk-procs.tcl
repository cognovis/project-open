# /packages/intranet-helpdesk/tcl/intranet-helpdesk-procs.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_ticket_status_open {} { return 30000 }
ad_proc -public im_ticket_status_closed {} { return 30001 }

ad_proc -public im_ticket_status_internal_review {} { return 30010 }
ad_proc -public im_ticket_status_assigned {} { return 30011 }
ad_proc -public im_ticket_status_customer_review {} { return 30012 }

ad_proc -public im_ticket_status_duplicate {} { return 30090 }
ad_proc -public im_ticket_status_invalid {} { return 30091 }
ad_proc -public im_ticket_status_outdated {} { return 30092 }
ad_proc -public im_ticket_status_rejected {} { return 30093 }
ad_proc -public im_ticket_status_wontfix {} { return 30094 }
ad_proc -public im_ticket_status_cantreproduce {} { return 30095 }
ad_proc -public im_ticket_status_fixed {} { return 30096 }
ad_proc -public im_ticket_status_deleted {} { return 30097 }
ad_proc -public im_ticket_status_canceled {} { return 30098 }


# ----------------------------------------------------------------------
# PackageID
# ----------------------------------------------------------------------

ad_proc -public im_package_helpdesk_id {} {
    Returns the package id of the intranet-helpdesk module
} {
    return [util_memoize "im_package_helpdesk_id_helper"]
}

ad_proc -private im_package_helpdesk_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-helpdesk'
    } -default 0]
}


# ----------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

ad_proc -public im_ticket_permissions {
    user_id 
    ticket_id 
    view_var 
    read_var 
    write_var 
    admin_var
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $ticket_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 1
    set write 1
    set admin 1
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_ticket_project_component {
    -object_id
} {
    Returns a HTML component to show all project tickets related to a project
} {
    set params [list \
		    [list base_url "/intranet-helpdesk/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-helpdesk/www/tickets-list-component"]
    return [string trim $result]
}
