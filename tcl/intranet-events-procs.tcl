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





ad_proc event_list_for_user_and_time_period {user_id first_julian_date last_julian_date} {
    For a given user and time period, this proc returns a list 
    of elements where each element corresponds to one day and describes its
    "work/vacation type".
    ToDo: Fix or remove
} {
    # Select all vacation periods that have at least one day
    # in the given time period.
    set sql "
	-- Direct events owner_id = user_id
	select
                to_char(start_date,'yyyy-mm-dd') as start_date,
                to_char(end_date,'yyyy-mm-dd') as end_date,
		im_category_from_id(event_type_id) as event_type,
		im_category_from_id(event_status_id) as event_status,
		event_id
	from 
		im_events
	where 
		owner_id = :user_id and
		group_id is null and
		start_date <= to_date(:last_julian_date,'J') and
		end_date   >= to_date(:first_julian_date,'J')
    UNION
	-- Events via groups - Check if the user is a member of group_id
	select
		to_char(start_date,'yyyy-mm-dd') as start_date,
		to_char(end_date,'yyyy-mm-dd') as end_date,
		im_category_from_id(event_type_id) as event_type,
		im_category_from_id(event_status_id) as event_status,
		event_id
	from 
		im_events
	where 
		group_id in (
                        select
                                group_id
                        from
                                group_element_index gei,
                                membership_rels mr
                        where
                                gei.rel_id = mr.rel_id and
                                mr.member_state = 'approved' and
                                gei.element_id = :user_id
		) and
		start_date <= to_date(:last_julian_date,'J') and
		end_date   >= to_date(:first_julian_date,'J')
    "


    # Initialize array with "" elements.
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
	set vacation($i) ""
    }

    # Process vacation periods and modify array accordingly.
    db_foreach vacation_period $sql {
    
	set event_status_3letter [string range $event_status 0 2]
        set event_status_3letter_l10n [lang::message::lookup "" intranet-events.Event_status_3letter_$event_status_3letter $event_status_3letter]
	set absent_status_3letter_l10n $event_status_3letter_l10n

	regsub " " $event_type "_" event_type_key
	set event_type_l10n [lang::message::lookup "" intranet-core.$event_type_key $event_type]

	set start_date_julian [db_string get_data "select to_char('$start_date'::date,'J')" -default 0]
	set end_date_julian [db_string get_data "select to_char('$end_date'::date,'J')" -default 0]

	for {set i [max $start_date_julian $first_julian_date]} {$i<=[min $end_date_julian $last_julian_date]} {incr i } {
	   set vacation($i) "
		<a href=\"/intranet-events/events/new?form_mode=display&event_id=$event_id\"
		>[_ intranet-events.Absent_1]</a> 
		$event_type_l10n<br>
           "
	}
    }
    # Return the relevant part of the array as a list.
    set result [list]
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
	lappend result $vacation($i)
    }
    return $result
}


ad_proc im_timesheet_events_sum { 
    -user_id:required
    {-number_days 7} 
} {
    Returns the total number of events multiplied by 8 hours per event.
    ToDo: Fix or remove
} {
    set hours_per_event [parameter::get -package_id [im_package_timesheet2_id] -parameter "TimesheetHoursPerEvent" -default 8]

    set num_events [db_string events_sum "
	select	count(*)
	from	im_events a,
		im_day_enumerator(now()::date - '7'::integer, now()::date) d
	where	owner_id = :user_id
		and a.start_date <= d.d
		and a.end_date >= d.d
    "]

    return [expr $num_events * $hours_per_event]
}


ad_proc -public im_get_next_event_link { { user_id } } {
    Returns a html link with the next "personal"event of the given user_id.
    Do not show Bank Holidays.
    ToDo: Fix or remove
} {
    set sql "
	select	event_id,
		to_char(start_date,'yyyy-mm-dd') as start_date,
		to_char(end_date, 'yyyy-mm-dd') as end_date
	from
		im_events, dual
	where
		owner_id = :user_id and
		group_id is null and
		start_date >= now()
	order by
		start_date, end_date
    "

    set ret_val ""
    db_foreach select_next_event $sql {
	set ret_val "<a href=\"/intranet-events/events/new?form_mode=display&event_id=$event_id\">$start_date - $end_date</a>"
	break
    }
    return $ret_val
}


# ---------------------------------------------------------------------
# Event Cube
# ---------------------------------------------------------------------

ad_proc im_event_cube_color_list { } {
    Returns the list of colors for the various types of events
} {
    # ad_return_complaint 1 [util_memoize im_event_cube_color_list_helper]
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


ad_proc im_event_mix_colors {
    value
} {
    Renders a single report cell, depending on value.
    Value consists of a string of 0..5 representing the last digit
    of the event_type:
            5000 | Vacation	- Red
            5001 | Personal	- Orange
            5002 | Sick		- Blue
            5003 | Travel	- Purple
            5004 | Training	- Yellow
            5005 | Bank Holiday	- Grey
    " " indentifies an "empty vacation", which is represented with
    color white. This is necessary to represent weekly events,
    where less then 5 days are taken as event.
    Value contains a string of last digits of the event types.
    Multiple values are possible for example "05", meaning that
    a Vacation and a holiday meet. 
} {
    # Show empty cells according to even/odd row formatting
    if {"" == $value} { return "" }
    set value [string toupper $value]

    # Define a list of colours to pick from
    set color_list [im_event_cube_color_list]

    set hex_list {0 1 2 3 4 5 6 7 8 9 A B C D E F}

    set len [string length $value]
    set r 0
    set g 0
    set b 0
    
    # Mix the colors for each of the characters in "value"
    for {set i 0} {$i < $len} {incr i} {
	set v [string range $value $i $i]

	set col "FFFFFF"
	if {" " != $v} { set col [lindex $color_list $v] }

	set r [expr $r + [lsearch $hex_list [string range $col 0 0]] * 16]
	set r [expr $r + [lsearch $hex_list [string range $col 1 1]]]
	
	set g [expr $g + [lsearch $hex_list [string range $col 2 2]] * 16]
	set g [expr $g + [lsearch $hex_list [string range $col 3 3]]]
	
	set b [expr $b + [lsearch $hex_list [string range $col 4 4]] * 16]
	set b [expr $b + [lsearch $hex_list [string range $col 5 5]]]
    }
    
    # Calculate the median
    set r [expr $r / $len]
    set g [expr $g / $len]
    set b [expr $b / $len]

    # Convert the RGB values back into a hex color string
    set color ""
    append color [lindex $hex_list [expr $r / 16]]
    append color [lindex $hex_list [expr $r % 16]]
    append color [lindex $hex_list [expr $g / 16]]
    append color [lindex $hex_list [expr $g % 16]]
    append color [lindex $hex_list [expr $b / 16]]
    append color [lindex $hex_list [expr $b % 16]]

    return $color
}



ad_proc im_event_cube_render_cell {
    value
} {
    Renders a single report cell, depending on value.
    Takes the color from events color lookup.
} {
    set color [im_event_mix_colors $value]
    if {"" != $color} {
	return "<td bgcolor=\#$color>&nbsp;</td>\n"
    } else {
	return "<td>&nbsp;</td>\n"
    }
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


ad_proc -public im_get_next_event_link { { user_id } } {
    Returns a html link with the next "personal"event of the given user_id.
    Do not show Bank Holidays.
} {
    set sql "
	select	event_id,
		to_char(start_date,'yyyy-mm-dd') as start_date,
		to_char(end_date, 'yyyy-mm-dd') as end_date
	from
		im_events, dual
	where
		owner_id = :user_id and
		group_id is null and
		start_date >= to_date(sysdate::text,'yyyy-mm-dd')
	order by
		start_date, end_date
    "

    set ret_val ""
    db_foreach select_next_event $sql {
	set ret_val "<a href=\"/intranet-events/events/new?form_mode=display&event_id=$event_id\">$start_date - $end_date</a>"
	break
    }
    return $ret_val
}

