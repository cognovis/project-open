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

    ad_proc -public next_ticket_nr {
    } {
        Create a new ticket_nr. Calculates the max() of current
	ticket_nrs and add +1

        @author frank.bergmann@project-open.com
	@return ticket_nr +1
    } {
	set last_ticket_nr [db_string last_pnr "
		select	max(project_nr)
		from	im_projects
		where	project_type_id = [im_project_type_ticket]
			and project_nr ~ '^\[0-9\]+$'
	" -default 0]

	# Make sure the counter is not behind the current value
	while {[db_string lv "select im_ticket_seq.last_value"] < $last_ticket_nr} {
	    set ttt [db_string update "select nextval('im_ticket_seq')"]
	}
	return [expr $last_ticket_nr + 1]
    }


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


ad_proc -public im_helpdesk_ticket_sla_options {
    {-mine_p 0}
    {-customer_id 0}
    {-include_empty_p 1}
    {-include_create_sla_p 0}
} {
    Returns a list of SLA tuples suitable for ad_form
} {
    set user_id [ad_get_user_id]

    # Can the user see all projects?
    set permission_sql ""
    if {![im_permission $user_id "view_project_all"]} {
	set include_create_sla_p 0
	set permission_sql "and p.project_id in (
		select object_id_one from acs_rels where object_id_two = :user_id UNION 
		select project_id from im_projects where company_id = :customer_id UNION
		select project_id from im_projects where company_id in (
			select	object_id_one
			from	acs_rels
			where	object_id_two = :user_id
		)
	)"
    }

    set sql "
	select
		c.company_name || ' (' || p.project_name || ')' as sla_name,
		p.project_id
	from
		im_projects p,
		im_companies c
	where
		p.company_id = c.company_id and
		p.project_type_id = [im_project_type_sla]
		$permission_sql
	order by
		sla_name
    "

    set options [list]
    db_foreach slas $sql {
	lappend options [list $sla_name $project_id]
    }

    if {$include_create_sla_p} { set options [linsert $options 0 [list [lang::message::lookup "" intranet-helpdesk.Create_New_SLA "Create New SLA"] "new"]] }
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }

    return $options
}


ad_proc -public im_helpdesk_home_component {
    {-show_empty_ticket_list_p 1}
    {-view_name "ticket_personal_list" }
    {-order_by_clause ""}
    {-ticket_type_id 0}
    {-ticket_status_id 0}
} {
    Returns a HTML table with the list of tickets of the
    current user. Don't do any fancy sorting and pagination, 
    because a single user won't be a member of many active tickets.

    @param show_empty_ticket_list_p Should we show an empty ticket list?
           Setting this parameter to 0 the component will just disappear
           if there are no tickets.
} {
    set current_user_id [ad_get_user_id]

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-helpdesk" -parameter "HomeTicketListSortClause" -default "p.project_nr DESC"]
    }
    set org_order_by_clause $order_by_clause


    # ---------------------------------------------------------------
    # Columns to show:

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]

    set column_sql "
	select	*
	from	im_view_columns
	where	view_id = :view_id and group_id is null
	order by sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    set extra_select [join $extra_selects ",\n\t"]
    set extra_from [join $extra_froms ",\n\t"]
    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_select] } { set extra_select ",\n\t$extra_select" }
    if { ![empty_string_p $extra_from] } { set extra_from ",\n\t$extra_from" }
    if { ![empty_string_p $extra_where] } { set extra_where "and\n\t$extra_where" }

    if {0 == $ticket_status_id} { set ticket_status_id [im_ticket_status_open] }


    set ticket_status_restriction ""
    if {0 != $ticket_status_id} { set ticket_status_restriction "and t.ticket_status_id in ([join [im_sub_categories $ticket_status_id] ","])" }

    set ticket_type_restriction ""
    if {0 != $ticket_type_id} { set ticket_type_restriction "and t.ticket_type_id in ([join [im_sub_categories $ticket_type_id] ","])" }

    set perm_sql "
	(select
		p.*
	from
	        im_tickets t,
		im_projects p
	where
		t.ticket_id = p.project_id
		and (
			t.ticket_assignee_id = :current_user_id 
			OR t.ticket_customer_contact_id = :current_user_id
			OR t.ticket_queue_id in (
				select distinct
					g.group_id
				from	acs_rels r, groups g 
				where	r.object_id_one = g.group_id and
					r.object_id_two = :current_user_id
			)
			OR p.project_id in (	
				-- cases with user as task holding_user
				select distinct wfc.object_id
				from	wf_tasks wft,
					wf_cases wfc
				where	wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id and
					wft.holding_user = :current_user_id
			) OR p.project_id in (
				-- cases with user as task_assignee
				select distinct wfc.object_id
				from	wf_task_assignments wfta,
					wf_tasks wft,
					wf_cases wfc
				where	wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id and
					wfta.task_id = wft.task_id and
					wfta.party_id in (
						select	group_id
						from	group_distinct_member_map
						where	member_id = :current_user_id
					    UNION
						select	:current_user_id
					)
			)
		)
		and t.ticket_status_id not in ([im_ticket_status_deleted], [im_ticket_status_closed])
		$ticket_status_restriction
		$ticket_type_restriction
	)"

    set personal_ticket_query "
	SELECT
		p.*,
		t.*,
		to_char(p.end_date, 'YYYY-MM-DD HH24:MI') as end_date_formatted,
	        c.company_name,
	        im_category_from_id(t.ticket_type_id) as ticket_type,
	        im_category_from_id(t.ticket_status_id) as ticket_status,
	        im_category_from_id(t.ticket_prio_id) as ticket_prio,
	        to_char(end_date, 'HH24:MI') as end_date_time
                $extra_select
	FROM
		$perm_sql p,
		im_tickets t,
		im_companies c
                $extra_from
	WHERE
		p.project_id = t.ticket_id and
		p.company_id = c.company_id
		$ticket_status_restriction
		$ticket_type_restriction
                $extra_where
	order by $org_order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    }
    append table_header_html "</tr>\n"


    # ---------------------------------------------------------------
    # Format the Result Data

    set url "index?"
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    db_foreach personal_ticket_query $personal_ticket_query {

	set url [im_maybe_prepend_http $url]
	if { [empty_string_p $url] } {
	    set url_string "&nbsp;"
	} else {
	    set url_string "<a href=\"$url\">$url</a>"
	}
	
	# Append together a line of data based on the "column_vars" parameter list
	set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td valign=top>"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
	append row_html "</tr>\n"
	append table_body_html $row_html
	
	incr ctr
    }

    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {

	# Let the component disappear if there are no tickets...
	if {!$show_empty_ticket_list_p} { return "" }

	set table_body_html "
	    <tr><td colspan=\"$colspan\"><ul><li><b> 
	    There are currently no tickets matching the selected criteria
	    </b></ul></td></tr>
	"
    }
    return "
	<table width=\"100%\" cellpadding=2 cellspacing=2 border=0>
	  $table_header_html
	  $table_body_html
	</table>
    "
}

