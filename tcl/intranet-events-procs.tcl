# /packages/intranet-events/tcl/intranet-events-procs.tcl
#
# Copyright (C) 2003-2013 ]project-open[


ad_library {
    Definitions for events

    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

ad_proc -public im_event_type_default {} { return 82000 }

ad_proc -public im_event_status_unplanned {} { return 82000 }
ad_proc -public im_event_status_planned {} { return 82002 }
ad_proc -public im_event_status_reserved {} { return 82004 }
ad_proc -public im_event_status_booked {} { return 82006 }

# Status for each event participant
ad_proc -public im_event_participant_status_confirmed {} { return 82200 }
ad_proc -public im_event_participant_status_reserved {} { return 82210 }
ad_proc -public im_event_participant_status_deleted {} { return 82290 }



namespace eval im_event {

# ----------------------------------------------------------------------
# Event - Timesheet Task Sweeper
# ---------------------------------------------------------------------

    ad_proc -public task_sweeper {
	{-sweep_mode "full"}
	{-sweep_last_interval "60 minutes" }
	{-event_id ""}
    } {
        Periodic sweeper that checks that every event 
	is represented by a timesheet task with the same members,
	so that event trainers can log their hours.

	@param full_sweep_p Normally sweeps only affect events
	       without task or recently modified events.
        @author frank.bergmann@project-open.com
    } {
	# -------------------------------------------------
	# Constants etc.
	set year [db_string year "select to_char(now()::date, 'YYYY') from dual"]

	# -------------------------------------------------
	# Determine which events to sweep

	# Default: Sweep only recently modified events or 
	# completely dirty ones (no timesheet task entry)
	set sweep_sql "
		select	e.*
		from	im_events e,
			acs_objects o
		where	e.event_id = o.object_id and
			(	-- no task yet
				event_timesheet_task_id is null
			OR	-- never swept yet
				event_timesheet_last_swept is null
			OR	-- modified since last sweep
				o.last_modified > event_timesheet_last_swept
			)
	"
	# Full sweep - sweep all events, which may take minutes...
	if {"full" == $sweep_mode} {
	    set sweep_sql "select e.* from im_events e"
	}

	# Sweep only a specific event
	if {"" != $event_id && [string is integer $event_id]} { 
	    set sweep_sql "select e.* from im_events e where e.event_id = $event_id" 
	}

	# -------------------------------------------------
        # Check the situation of relevant events
	db_foreach sweep_events $sweep_sql {
	    
	    # Make sure the parent project exists
	    set parent_project_id [db_string parent_project_id "
		select	project_id
		from	im_projects
		where	project_nr = :year || '_events'
	    " -default ""]
	    if {"" == $parent_project_id} {
		set parent_project_id [project::new \
					   -project_name       "$year Events" \
					   -project_nr         "${year}_events" \
					   -project_path       "${year}_events" \
					   -company_id         [im_company_internal] \
					   -parent_id          "" \
					   -project_type_id    [im_project_type_consulting] \
					   -project_status_id  [im_project_status_open] \
		]
		db_dml update_parent_project "
			update im_projects set
			    	start_date = to_date(:year || '-01-01', 'YYYY-MM-DD'),
				end_date = to_date(:year || '-12-31', 'YYYY-MM-DD')
			where project_id = :parent_project_id
		"
	    }
	    set task_nr "event_$event_nr"
	    set task_name "Event $event_nr"

	    # -----------------------------------------------------
	    # Create the timesheet task
	    set task_id [db_string task_id "
	    	select	p.project_id
		from	im_projects p,
			im_timesheet_tasks t
		where	p.project_id = t.task_id and
			p.parent_id = :parent_project_id and
			p.project_nr = :task_nr
	    " -default ""]

	    set project_id $parent_project_id
	    set material_id [im_material_default_material_id]
	    set cost_center_id ""
	    set uom_id [im_uom_hour]
	    set task_type_id [im_project_type_task]
	    set task_status_id [im_project_status_open]
	    set note $event_description
	    set planned_units 0
	    set billable_units 0
	    set percent_completed ""

	    if {"" == $task_id} {
		set task_id [db_string task_insert {}]
	    }
	    db_dml task_update {}
	    db_dml project_update {}

	    db_dml update_event "
		update im_events
		set event_timesheet_task_id = :task_id
		where event_id = :event_id
	    "

	    # -----------------------------------------------------
	    # Copy event members to task
	    set event_member_sql "
		select	object_id_two as user_id,
			bom.object_role_id as role_id
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			object_id_one = :event_id
	    "
	    array set event_member_hash {}
	    db_foreach event_members $event_member_sql {
		im_biz_object_add_role -percentage 100 $user_id $task_id $role_id
		set event_member_hash($user_id) $role_id
	    }

	    # -----------------------------------------------------
	    # Remove task members who are not event members
	    set task_member_sql "
		select	object_id_two as user_id,
			bom.object_role_id as role_id
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			object_id_one = :task_id
	    "
	    array set task_member_hash {}
	    db_foreach task_members $task_member_sql {
		set task_member_hash($user_id) $role_id
	    }

	    foreach uid [array names task_member_hash] {
		if {![info exists event_member_hash($uid)]} {
		    db_string delete_membership "
		    	select im_biz_object_member__delete(:task_id, :uid)
		    "
		}
	    }

	    # Marks as swept
	    db_dml update_event "
		update im_events
		set event_timesheet_last_swept = now()
		where event_id = :event_id
	    "

	    # Write Audit Trail
	    im_project_audit -project_id $task_id -action after_create
	}
    }

    # ----------------------------------------------------------------------
    # Generate unique event_nr
    # ---------------------------------------------------------------------

    ad_proc -public next_event_nr {
    } {
        Create a new event_nr. Calculates the max() of current
	event_nrs and add +1, or just use a sequence for the next value.

        @author frank.bergmann@project-open.com
	@return next event_nr
    } {
	set next_event_nr_method [parameter::get_from_package_key -package_key "intranet-events" -parameter "NextEventNrMethod" -default "sequence"]

	switch $next_event_nr_method {
	    sequence {
		# Make sure everybody _really_ gets a different NR!
		return [db_nextval im_event_nr_seq]
	    }
	    default {
		# Try to avoid any "holes" in the list of event NRs
		set last_event_nr [db_string last_pnr "
		select	max(event_nr::integer)
		from	im_events
		where	event_nr ~ '^\[0-9\]+$'
	        " -default 0]

		# Make sure the counter is not behind the current value
		while {[db_string last_value "select im_event_nr_seq.last_value from dual"] < $last_event_nr} {
		    db_dml update "select nextval('im_event_seq')"
		}
		return [expr $last_event_nr + 1]
	    }
	}
    }
}



# ---------------------------------------------------------------------
# Event Customer Component
# ---------------------------------------------------------------------

ad_proc im_event_customer_component { event_id form_mode orderby return_url } {
    Returns a formatted HTML showing the event customers, customer members and related order items
} {
    set params [list \
                    [list event_id $event_id] \
                    [list form_mode $form_mode] \
                    [list orderby $orderby] \
                    [list return_url $return_url] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-events/lib/event-customers"]
    return [string trim $result]
}



ad_proc im_event_order_item_component { event_id form_mode orderby return_url } {
    Returns a formatted HTML showing the event order_items
} {
    set params [list \
                    [list event_id $event_id] \
                    [list form_mode $form_mode] \
                    [list orderby $orderby] \
                    [list return_url $return_url] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-events/lib/event-order-items"]
    return [string trim $result]
}


ad_proc im_event_participant_component { event_id form_mode orderby return_url } {
    Returns a formatted HTML showing the event participants, participant members and related order items
} {
    set params [list \
                    [list event_id $event_id] \
                    [list form_mode $form_mode] \
                    [list orderby $orderby] \
                    [list return_url $return_url] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-events/lib/event-participants"]
    return [string trim $result]
}


# ---------------------------------------------------------------------
# Events Permissions
# ---------------------------------------------------------------------

ad_proc -public im_event_permissions {user_id event_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $event_id
    ToDo: Implement
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin
    
    set view 1
    set read 1
    set write 1
    set admin 1
    
    # No read - no write...
    if {!$read} {
        set write 0
        set admin 0
    }
}



# ----------------------------------------------------------------------
# Navigation Bar
# ---------------------------------------------------------------------

ad_proc -public im_event_navbar { 
    {-navbar_menu_label "events"}
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet-events/.
    The lower part of the navbar also includes an Alpha bar.

    @param default_letter none marks a special behavious, hiding the alpha-bar.
    @navbar_menu_label Determines the "parent menu" for the menu tabs for 
       search shortcuts, defaults to "projects".
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
    set url_stub [ns_urldecode [im_url_with_query]]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label = '$navbar_menu_label'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
}


# ---------------------------------------------------------------------
# Event Cube
# ---------------------------------------------------------------------

ad_proc im_event_cube_color_list { } {
    Returns the list of colors for the various types of events
} {
#    return [util_memoize im_event_cube_color_list_helper]
    return [im_event_cube_color_list_helper]
}


ad_proc im_event_cube_color_list_helper { } {
    Returns the list of colors for the various types of events
} {
    # define default color set 
    set color_list {
        EC9559
        E2849B
        53A7D8
        A185CB
        FFF956
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
        CCCCC9
    }

    # Overwrite in case there's a custom color defined 
    set col_sql "
        select  category_id, category, enabled_p, aux_string2
        from    im_categories
        where	category_type = 'Intranet Event Type'
        order by category_id
     "

    set ctr 0 
    db_foreach cols $col_sql {
	if { "" == $aux_string2 } {
	    lset color_list $ctr [lindex $color_list $ctr]
	} else {
	    lset color_list $ctr $aux_string2
	}
	incr ctr
    }
    return $color_list

}

ad_proc im_event_cube {
    {-num_days 21}
    {-event_status_id "" }
    {-event_type_id "" }
    {-user_selection "" }
    {-timescale "" }
    {-report_start_date "" }
    {-user_id_from_search "" }
} {
    Returns a rendered cube with a graphical event display
    for users.
} {
    switch $timescale {
	today { return "" }
	all { return "" }
	next_3w { set num_days 21 }
	last_3w { set num_days 21 }
	next_1m { set num_days 31 }
	past { return "" }
	future { set num_days 93 }
	last_3m { set num_days 93 }
	next_3m { set num_days 93 }
	default {
	    set num_days 31
	}
    }

    set user_url "/intranet/users/view"
    set date_format "YYYY-MM-DD"
    set current_user_id [ad_get_user_id]
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]

    if {"" == $report_start_date || "2000-01-01" == $report_start_date} {
	set report_start_date [db_string start_date "select now()::date"]
    }

    set report_end_date [db_string end_date "select :report_start_date::date + :num_days::integer"]

    if {-1 == $event_type_id} { set event_type_id "" }

    # ---------------------------------------------------------------
    # Limit the number of users and days
    # ---------------------------------------------------------------

    set criteria [list]
    if {"" != $event_type_id && 0 != $event_type_id} {
	lappend criteria "a.event_type_id = '$event_type_id'"
    }
    if {"" != $event_status_id && 0 != $event_status_id} {
	lappend criteria "a.event_status_id = '$event_status_id'"
    }

    switch $user_selection {
	"all" {
	    # Nothing.
	}
	"mine" {
	    lappend criteria "u.user_id = :current_user_id"
	}
	"employees" {
	    lappend criteria "u.user_id IN (select	m.member_id
                                                        from	group_approved_member_map m
                                                        where	m.group_id = [im_employee_group_id]
                                                        )"
	    
	}
	"providers" {
	    lappend criteria "u.user_id IN (select	m.member_id 
							from	group_approved_member_map m 
							where	m.group_id = [im_freelance_group_id]
							)"
	}
	"customers" {
	    lappend criteria "u.user_id IN (select	m.member_id
                                                        from	group_approved_member_map m
                                                        where	m.group_id = [im_customer_group_id]
                                                        )"
	}
	"direct_reports" {
	    lappend criteria "a.owner_id in (select employee_id from im_employees where supervisor_id = :current_user_id)"
	}  
	default  {
	    if {[string is integer $user_selection]} {
		lappend criteria "u.user_id = :user_selection"
	    } else {
		# error message in index.tcl
	    }
	}
    }
    set where_clause [join $criteria " and\n            "]
    if {![empty_string_p $where_clause]} {
	set where_clause " and $where_clause"
    }

    # ---------------------------------------------------------------
    # Determine Top Dimension
    # ---------------------------------------------------------------
    
    # Initialize the hash for holidays.
    array set holiday_hash {}
    set day_list [list]
    
    for {set i 0} {$i < $num_days} {incr i} {
	db_1row date_info "
	    select 
		to_char(:report_start_date::date + :i::integer, :date_format) as date_date,
		to_char(:report_start_date::date + :i::integer, 'Day') as date_day,
		to_char(:report_start_date::date + :i::integer, 'dd') as date_day_of_month,
		to_char(:report_start_date::date + :i::integer, 'Mon') as date_month,
		to_char(:report_start_date::date + :i::integer, 'YYYY') as date_year,
		to_char(:report_start_date::date + :i::integer, 'Dy') as date_weekday
        "

	set date_month [lang::message::lookup "" intranet-events.$date_month $date_month]

	if {$date_weekday == "Sat" || $date_weekday == "Sun"} { set holiday_hash($date_date) 5 }
	lappend day_list [list $date_date $date_day_of_month $date_month $date_year]
    }

    # ---------------------------------------------------------------
    # Determine Left Dimension
    # ---------------------------------------------------------------
    
    set user_list [db_list_of_lists user_list "
	select	u.user_id as user_id,
		im_name_from_user_id(u.user_id, $name_order) as user_name
	from	users u,
		cc_users cc
	where	u.user_id in (
			-- Individual Events per user
			select	a.owner_id
			from	im_events a,
				users u
			where	a.owner_id = u.user_id and
				a.start_date <= :report_end_date::date and
				a.end_date >= :report_start_date::date
				$where_clause
		     UNION
			-- Events for user groups
			select	mm.member_id as owner_id
			from	im_events a,
				users u,
				group_distinct_member_map mm
			where	mm.member_id = u.user_id and
				a.start_date <= :report_end_date::date and
				a.end_date >= :report_start_date::date and
				mm.group_id = a.group_id
				$where_clause
		)
		and cc.member_state = 'approved'
		and cc.user_id = u.user_id
	order by
		lower(im_name_from_user_id(u.user_id, $name_order))
    "]


    # Get list of categeory_ids to determine index 
    # needed for color codes

    set sql "
        select  category_id
        from    im_categories
        where   category_type = 'Intranet Event Type'
        order by category_id
     "

    set category_list [list]
    db_foreach category_id $sql {
	lappend category_list [list $category_id]
    }

    # ---------------------------------------------------------------
    # Get individual events
    # ---------------------------------------------------------------
    
    array set event_hash {}
    set event_sql "
	-- Individual Events per user
	select	a.event_type_id,
		a.owner_id,
		d.d
	from	im_events a,
		users u,
		(select im_day_enumerator as d from im_day_enumerator(:report_start_date, :report_end_date)) d,
		cc_users cc
	where	a.owner_id = u.user_id and
		cc.user_id = u.user_id and 
		cc.member_state = 'approved' and
		a.start_date <= :report_end_date::date and
		a.end_date >= :report_start_date::date and
                date_trunc('day',d.d) between date_trunc('day',a.start_date) and date_trunc('day',a.end_date) 
		$where_clause
     UNION
	-- Events for user groups
	select	a.event_type_id,
		mm.member_id as owner_id,
		d.d
	from	im_events a,
		users u,
		group_distinct_member_map mm,
		(select im_day_enumerator as d from im_day_enumerator(:report_start_date, :report_end_date)) d
	where	mm.member_id = u.user_id and
		a.start_date <= :report_end_date::date and
		a.end_date >= :report_start_date::date and
                date_trunc('day',d.d) between date_trunc('day',a.start_date) and date_trunc('day',a.end_date) and 
		mm.group_id = a.group_id
		$where_clause
    "

    # ToDo: re-factor so that color codes also work in case of more than 10 event types
    db_foreach events $event_sql {
	set key "$owner_id-$d"
	set value ""
	if {[info exists event_hash($key)]} { set value $event_hash($key) }
	set event_hash($key) [append value [lsearch $category_list $event_type_id]]
    }

    # ---------------------------------------------------------------
    # Render the table
    # ---------------------------------------------------------------
    
    set table_header "<tr class=rowtitle>\n"
    append table_header "<td class=rowtitle>[_ intranet-core.User]</td>\n"
    foreach day $day_list {
	set date_date [lindex $day 0]
	set date_day_of_month [lindex $day 1]
	set date_month_of_year [lindex $day 2]
	set date_year [lindex $day 3]
	append table_header "<td class=rowtitle>$date_month_of_year<br>$date_day_of_month</td>\n"
    }
    
    append table_header "</tr>\n"
    set row_ctr 0
    set table_body ""
    foreach user_tuple $user_list {
	append table_body "<tr $bgcolor([expr $row_ctr % 2])>\n"
	set user_id [lindex $user_tuple 0]
	set user_name [lindex $user_tuple 1]
	append table_body "<td><nobr><a href='[export_vars -base $user_url {user_id}]'>$user_name</a></td></nobr>\n"
	foreach day $day_list {
	    set date_date [lindex $day 0]
	    set key "$user_id-$date_date"
	    set value ""
	    if {[info exists event_hash($key)]} { set value $event_hash($key) }
	    if {[info exists holiday_hash($date_date)]} { append value $holiday_hash($date_date) }
	    append table_body [im_event_cube_render_cell $value]
	    ns_log NOTICE "intranet-events-procs::im_event_cube_render_cell: $value"
	}
	append table_body "</tr>\n"
	incr row_ctr
    }

    return "
	<table>
	$table_header
	$table_body
	</table>
    "
}

