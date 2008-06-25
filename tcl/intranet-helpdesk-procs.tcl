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


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

namespace eval im_ticket {

    ad_proc -public new {
        { -var_hash "" }
    } {
        Create a new ticket. There are only few required field.
	Primary key is ticket_nr which defaults to ticket_name.

        @author frank.bergmann@project-open.com
	@return The object_id of the new (or existing) ticket
    } {
	array set vars $var_hash
	set ticket_new_sql "
		SELECT im_ticket__new (
			:ticket_id,		-- p_ticket_id
			'im_ticket',		-- object_type
			now(),			-- creation_date
			0,			-- creation_user
			'0.0.0.0',		-- creation_ip
			null,			-- context_id
	
			:ticket_name,
			:ticket_customer_id,
			:ticket_type_id,
			:ticket_status_id
		)
	"

	# Set defaults.
	set ticket_name $vars(ticket_name)
	set ticket_nr $ticket_name
	set ticket_parent_id ""
	set ticket_status_id [im_ticket_status_active]
	set ticket_type_id [im_ticket_type_hardware]
	set ticket_version ""
	set ticket_owner_id [ad_get_user_id]
	set description ""
	set note ""

	# Override defaults
	if {[info exists vars(ticket_nr)]} { set ticket_nr $vars(ticket_nr) }
	if {[info exists vars(ticket_code)]} { set ticket_code $vars(ticket_nr) }
	if {[info exists vars(ticket_parent_id)]} { set ticket_parent_id $vars(ticket_parent_id) }
	if {[info exists vars(ticket_status_id)]} { set ticket_status_id $vars(ticket_status_id) }
	if {[info exists vars(ticket_type_id)]} { set ticket_type_id $vars(ticket_type_id) }
	if {[info exists vars(ticket_version)]} { set ticket_version $vars(ticket_version) }
	if {[info exists vars(ticket_owner_id)]} { set ticket_owner_id $vars(ticket_owner_id) }
	if {[info exists vars(description)]} { set description $vars(description) }
	if {[info exists vars(note)]} { set note $vars(note) }

	# Check if the item already exists
        set ticket_id [db_string exists "
		select	ticket_id
		from	im_tickets
		where
			ticket_parent_id = :ticket_parent_id and
			ticket_nr = :ticket_nr
	" -default 0]

	# Create a new item if necessary
        if {!$ticket_id} { set ticket_id [db_string new $ticket_new_sql] }

	# Update the item with additional variables from the vars array
	set sql_list [list]
	foreach var [array names vars] {
	    if {$var == "ticket_id"} { continue }
	    lappend sql_list "$var = :$var"
	}
	set sql "
		update im_tickets set
		[join $sql_list ",\n"]
		where ticket_id = :ticket_id
	"
        db_dml update_ticket $sql
	return $ticket_id
    }
}


ad_proc -public im_helpdesk_ticket_queue_options {
    {-mine_p 0}
    {-include_empty_p 1}
} {
    Returns a list of Ticket Queue tuples suitable for ad_form
} {
    set user_id [ad_get_user_id]

    set sql "
	select
		g.group_name,
		g.group_id
	from
		groups g,
		im_ticket_queue_ext q
	where
		g.group_id = q.group_id
	order by
		g.group_name
    "

    set options [list]
    db_foreach groups $sql {
	regsub -all " " $group_name "_" group_key
	set name [lang::message::lookup "" intranet-helpdesk.group_key $group_name]
	lappend options [list $name $group_id]
    }

    set options [db_list_of_lists company_options $sql]
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }

    return $options
}
