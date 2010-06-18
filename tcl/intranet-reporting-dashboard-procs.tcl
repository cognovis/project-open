# /packages/intranet-reporting-dashborad/tcl/intranet-reporting-dashboard-procs.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Dashboard
    @author frank.bergmann@project-open.com
}



# ----------------------------------------------------------------------
# Sweeper - Cleans up the dashboard cache
# ---------------------------------------------------------------------


ad_proc -public im_reporting_dashboard_sweeper { 
    dummy
} {
    Deletes old dashboard DW entries
} {
    # Delete _values_. 
    # It's not necessary to delete the cube definitions
    # (im_reporting_cubes). They also contain counters.
    db_dml del_values "delete from im_reporting_cube_values"
}

ad_proc -public im_reporting_dashboard_sweeper { } {
    Same procedure without argument
} {
    im_reporting_dashboard_sweeper 0
}


# ----------------------------------------------------------------------
# All Time Top Customers
# ---------------------------------------------------------------------


ad_proc -public im_dashboard_all_time_top_customers_component {
    { -ttt ""}
} {
    Returns a dashboard component for the home page
} {
    set menu_label "reporting-cubes-finance"
    set current_user_id [ad_maybe_redirect_for_registration]
    set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m where m.label = :menu_label
    " -default 'f']
    if {![string equal "t" $read_p]} { return "" }

    set params [list \
		    [list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-reporting-dashboard/www/all_time_top_customers"]
    return $result
}


# ----------------------------------------------------------------------
# Generic Component
# ---------------------------------------------------------------------

ad_proc -public im_dashboard_generic_component {
    { -component "generic" }
    { -component_name "Unknown Component Name" }
    { -cube_name "finance" }
    { -start_date "" }
    { -end_date "" }
    { -cost_type_id {3700} }
    { -top_vars "year" }
    { -left_vars "sub_project_type" }
} {
    Returns a dashboard component for the home page
} {
    set menu_label "reporting-cubes-finance"
    set current_user_id [ad_maybe_redirect_for_registration]
    set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m where m.label = :menu_label
    " -default 'f']
    if {![string equal "t" $read_p]} { return "" }

    if {"" == $start_date} { set start_date [db_string start "select to_date(now()::date-10000, 'YYYY-MM-01')"] }
    if {"" == $end_date} { set end_date [db_string start "select to_date(now()::date+60, 'YYYY-MM-01')"] }

    set params [list \
		    [list component_name $component_name] \
		    [list cube_name $cube_name] \
		    [list start_date $start_date] \
		    [list end_date $end_date] \
		    [list top_vars $top_vars] \
		    [list left_vars $left_vars] \
		    [list return_url [im_url_with_query]] \
		    ]
    set result [ad_parse_template -params $params "/packages/intranet-reporting-dashboard/www/$component"]
    return $result
}




# ----------------------------------------------------------------------
# Generic Histogram
# ---------------------------------------------------------------------

ad_proc -public im_dashboard_histogram_sql {
    -sql:required
    { -menu_label "" }
    { -name "" }
    { -diagram_width 400 }
} {
    Returns a dashboard component.
    Requires a SQL statement like 
    "select im_category_from_id(project_type_id), count(*) from im_projects group by project_type_id"
} {
    if {"" == $menu_label} { 
	set read_p "t" 
    } else {

	set current_user_id [ad_maybe_redirect_for_registration]
	set read_p [db_string report_perms "
	        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
	        from    im_menus m where m.label = :menu_label
        " -default 'f']
	if {![string equal "t" $read_p]} { return "" }
    }

    set values [db_list_of_lists dashboard_historgram $sql]

    return [im_dashboard_histogram \
		-name $name \
		-values $values \
		-diagram_width $diagram_width \
    ]
}


# ----------------------------------------------------------------------
# Status of currently non-closed projects
# ---------------------------------------------------------------------


ad_proc -public im_dashboard_active_projects_status_histogram {
} {
    Returns a dashboard component for the home page
} {
    set menu_label "reporting-cubes-finance"
    set current_user_id [ad_maybe_redirect_for_registration]
    set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m where m.label = :menu_label
    " -default 'f']
    if {![string equal "t" $read_p]} { return "" }

    set sql "
        select
		count(*) as cnt,
		project_status_id,
                im_category_from_id(project_status_id) as project_status
        from
		im_projects p
	where
		p.parent_id is null
		and p.project_status_id not in (
			[im_project_status_deleted],
			[im_project_status_canceled],
			[im_project_status_invoiced],
			[im_project_status_closed]
		)
        group by 
		project_status_id
	order by
		project_status_id
    "
    set values [list]
    db_foreach project_queue $sql {
	lappend values [list $project_status $cnt]
    }

    return [im_dashboard_histogram \
		-name "Project Queue" \
		-values $values \
    ]

}


# ----------------------------------------------------------------------
# Define a color bar from red to blue or similar...
# ----------------------------------------------------------------------

ad_proc im_dashboard_color { 
    { -type "" }
} {
    Returns suitable colors, depending on the respective skin
} {
    set skin_name [im_user_skin [ad_get_user_id]]

    if {[catch {
        set procname "im_dashboard_color_$skin_name"
	set color [$procname -type $type]
    } err_msg]} {
	set color [im_dashboard_color_default -type $type]
    }

    return $color
}


ad_proc im_dashboard_color_saltnpepper { 
    { -type "" }
} {
    Returns suitable colors
} {
    switch $type {

	start_color { return "216594" }
	end_color { return "08456B" }
	bar_color { return "216594" }
	bar_text_color { return "08456B" }
	pie_text_color { return "08456B" }
	bar_bg_color { return "FFFFFF" }
	default {
	    ad_return_complaint 1 "<br>im_dashboard_color: Unknown color type: '$type'</b>"
	}
    }
}


ad_proc im_dashboard_color_default { 
    { -type "" }
} {
    Returns suitable colors, depending on the respective skin
	start_color { return "0080FF" }
	end_color { return "FF8000" }
	bar_color { return "0080FF" }
} {
    switch $type {

	start_color { return "0080FF" }
	end_color { return "80FF80" }
	bar_color { return "0080FF" }
	bar_text_color { return "000000" }
	bar_bg_color { 
	    # Background of bar chart
	    return "FFFFFF" 
	}
	pie_text_color { return "000000" }

	default {
	    ad_return_complaint 1 "<br>im_dashboard_color_default: Unknown color type: '$type'</b>"
	}
    }
}



ad_proc im_dashboard_pie_colors { 
    { -max_entries 8 }
    { -start_color "" }
    { -end_color "" }
} {
    Returns an array with color codes from 0.. $max_entries
    (max_entries+1 in total)
} {
    if {"" == $start_color} { set start_color [im_dashboard_color -type "start_color"] }
    if {"" == $end_color} { set end_color [im_dashboard_color -type "end_color"] }

    # Aux string for hex conversions
    set h "0123456789ABCDEF"

    set red_start [expr 16 * [string first [string range $start_color 0 0] $h]]
    set red_start [expr $red_start + [string first [string range $start_color 1 1] $h]]
    set green_start [expr 16 * [string first [string range $start_color 2 2] $h]]
    set green_start [expr $green_start + [string first [string range $start_color 3 3] $h]]
    set blue_start [expr 16 * [string first [string range $start_color 4 4] $h]]
    set blue_start [expr $blue_start + [string first [string range $start_color 5 5] $h]]

    set red_end [expr 16 * [string first [string range $end_color 0 0] $h]]
    set red_end [expr $red_end + [string first [string range $end_color 1 1] $h]]
    set green_end [expr 16 * [string first [string range $end_color 2 2] $h]]
    set green_end [expr $green_end + [string first [string range $end_color 3 3] $h]]
    set blue_end [expr 16 * [string first [string range $end_color 4 4] $h]]
    set blue_end [expr $blue_end + [string first [string range $end_color 5 5] $h]]

    set max [expr $max_entries + 1]

    set blue_incr [expr 1.0 * ($blue_end - $blue_start) / $max]
    set red_incr [expr 1.0 * ($red_end - $red_start) / $max]
    set green_incr [expr 1.0 * ($green_end - $green_start) / $max]

    for {set i 0} {$i <= $max_entries} {incr i} {
        set blue [expr round($blue_start + round($i*$blue_incr))]
        set red [expr round($red_start + round($i*$red_incr))]
        set green [expr round($green_start + round($i*$green_incr))]
    
        set red_low [expr $red % 16]
        set red_high [expr round($red / 16)]
        set blue_low [expr $blue % 16]
        set blue_high [expr round($blue / 16)]
        set green_low [expr $green % 16]
        set green_high [expr round($green / 16)]
    
        set col "\#[string range $h $red_high $red_high][string range $h $red_low $red_low]"
        append col "[string range $h $green_high $green_high][string range $h $green_low $green_low]"
        append col "[string range $h $blue_high $blue_high][string range $h $blue_low $blue_low]"
    
        set pie_colors($i) $col
    }
    return [array get pie_colors]
}

# ----------------------------------------------------------------------
# Draw a reasonable Pie chart
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_chart { 
    { -max_entries 8 }
    { -values {} }
    { -bar_y_size 15 }
    { -bar_x_size 100 }
    { -perc_x_size 50 }
    { -radius 90 }
    { -bar_distance 5 }
    { -bar_text_limit "" }
    { -outer_distance 20 }
    { -start_color "" }
    { -end_color "" }
    { -font_color "" }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;" }
} {
    Returns a formatted HTML text to display a piechart
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param max_entries Determines the max. number of entries
           in the pie chart. It also determines the Y-size of the diagram.
    @param values A list of {name value} pairs to be displayed.
           Values must be numeric (comparable using the "<" operator).

    Short example:
	<pre>set pie_chart [im_dashboard_pie_chart \
        -max_entries 3 \
	-values {{Abc 10} {Bcde 20} {Cdefg 30} {Defg 25}}
	</pre>		       
} {
    if {"" == $font_color} { set font_color [im_dashboard_color -type "pie_text_color"] }
    if {[llength $values] < $max_entries} { set max_entries [llength $values] }

    set perc_x_start [expr $outer_distance + 2 * $radius + $outer_distance]
    set perc_x_end [expr $perc_x_start + $perc_x_size]

    set bar_x_start [expr $perc_x_end + $bar_distance]
    set bar_x_end [expr $bar_x_start + $bar_x_size]

    set diagram_x_size [expr $bar_x_end + $outer_distance]
    set diagram_y_size [expr $outer_distance + ($max_entries+1) * ($bar_y_size + $bar_distance) + $outer_distance]
    set diagram_y_size_circle [expr $outer_distance + 2*$radius + $outer_distance]
    if {$diagram_y_size_circle > $diagram_y_size} { set diagram_y_size $diagram_y_size_circle }
    
    if {"" == $bar_text_limit} { set bar_text_limit [expr round($bar_x_size / $font_size)] }

    # Get a range of suitable colors
    array set pie_colors [im_dashboard_pie_colors \
	-max_entries $max_entries \
	-start_color $start_color \
	-end_color $end_color \
    ]

    # Sum up the values as a 100% base to calculate percentages
    set pie_sum 0
    foreach value $values {
        set val [lindex $value 1]
        set pie_sum [expr $pie_sum + $val]
    }
    if {0 == $pie_sum} { set pie_sum 0.00001}
    
    # Sort list according to value (2nd element)
    set values [reverse [qsort $values [lambda {s} { lindex $s 1 }]]]
    
    # Format the elements
    set pie_pieces_html "\n"
    set pie_bars_html ""
    set count 0
    set angle 0
    foreach pie_degree $values {
        if {$count > $max_entries} { continue }

        set key [lindex $pie_degree 0]
        set val [lindex $pie_degree 1]
        set perc [expr round($val * 1000.0 / $pie_sum) / 10.0]
        set degrees [expr $val * 360.0 / $pie_sum]

        if {$count == $max_entries} { 
	    # "Other" section - fill the circle
	    set key "Other"
	    set degrees [expr 360.0 - $angle]
	    set perc [expr round(1000.0 * $degrees / 360.0) / 10.0]
	}

        set col $pie_colors($count)
        append pie_pieces_html "P\[$count\]=new Pie([expr $radius+$outer_distance], [expr $radius+$outer_distance], 0, $radius, [expr $angle-0.3], [expr $angle+$degrees+0.3], \"$col\");\n"

        set angle [expr $angle+$degrees]
        set perc_text "${perc}%"
        set pie_text [string range $key 0 $bar_text_limit]

	set perc_y_start [expr $outer_distance + $count * ($bar_y_size + $bar_distance)]
	set perc_y_end [expr $perc_y_start + $bar_y_size]
	set bar_y_start $perc_y_start
	set bar_y_end $perc_y_end

        append pie_bars_html "new Bar($perc_x_start, $perc_y_start, $perc_x_end, $perc_y_end, \"$col\", \"$perc_text\", \"\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    
        append pie_bars_html "new Bar($bar_x_start, $bar_y_start, $bar_x_end, $bar_y_end, \"$col\", \"$pie_text\", \"\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    
        incr count
    }
    
    set border "border:2px solid blue; "
    set border ""

    return "
        <div style='$border position:relative;top:0px;height:${diagram_y_size}px;width:${diagram_x_size}px;'>
        <SCRIPT Language=JavaScript>
        P=new Array();
        document.open();
        _BFont=\"color:\#$font_color;font-size:${font_size}pt;$font_style\";
        $pie_pieces_html
        $pie_bars_html
        document.close();
        function MouseOver(i) { P\[i\].MoveTo(\"\",\"\",10); }
        function MouseOut(i) { P\[i\].MoveTo(\"\",\"\",0); }
        </SCRIPT>
        </div>
    "
}


# ----------------------------------------------------------------------
# Draw a reasonable Histogram chart
# ----------------------------------------------------------------------

ad_proc im_dashboard_histogram {
    { -name "" }
    { -values {} }
    { -bar_width 10 }
    { -bar_distance 5 }
    { -bar_color "" }
    { -bar_bg_color "" }
    { -bar_text_color "" }
    { -outer_distance 20 }
    { -diagram_width 400 }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;" }
} {
    Returns a formatted HTML text to display a histogram chart
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.

    Short example:
	<pre>set histogram_chart [im_dashboard_histogram \
        -values {{Potential 10} {Quoting 5} {Open 5} {Invoicing 6}} \
	]</pre>
} {
    if {"" == $bar_color} { set bar_color [im_dashboard_color -type bar_color] }
    if {"" == $bar_text_color} { set bar_text_color [im_dashboard_color -type bar_text_color] }
    if {"" == $bar_bg_color} { set bar_bg_color [im_dashboard_color -type bar_bg_color] }

    # The total number of data items (both header and values)
    set value_total_items 0

    # The number of data set (each consisting of one header and several values)
    set value_data_sets 0
    
    # The biggest individual value
    set max_value 0

    # Generate a random name for the diagram. Cut off ".0" float extension.
    regexp {([0-9]*)} [expr 1E12 * rand()] match diag
    set diag "D$diag"

    foreach v $values {
	incr value_data_sets
	set value_total_items [expr $value_total_items + [llength $v]]
	set v_vals [lrange $v 1 end]
	foreach v_val $v_vals {
	    if {$v_val > $max_value} { set max_value $v_val}
	}
    }
    set value_data_len [expr $value_total_items - $value_data_sets]

    set diagram_x_size $diagram_width
    set diagram_y_size [expr 2*$outer_distance + $value_total_items*($bar_width + $bar_distance)]
    set diagram_y_start 25

    set count 1
    foreach v $values {

	set bar_title [lindex $v 0]
	set vals [lrange $v 1 end]

	append status_html "
		new Bar(
			1+$diag.ScreenX(0), $diag.ScreenY($count), 
			1+$diag.ScreenX($max_value), $bar_width + $diag.ScreenY($count),
			\"\", \"$bar_title\", \"#$bar_text_color\", \"$bar_title\",
			\"\", \"\", \"\", \"left\"
		);
	"
	incr count

	foreach cnt $vals {
	    append status_html "
		new Bar(
			1+$diag.ScreenX(0), $diag.ScreenY($count), 
			1+$diag.ScreenX($cnt), $bar_width + $diag.ScreenY($count),
			\"#$bar_color\", \"&nbsp;\", \"#$bar_text_color\", \"&nbsp;\", \"\"
		);
            "
	    incr count
	}
    }

    set border "border:1px solid blue; "
    set border ""

    # Calculate Name
    regsub -all " " $name "_" name_subs
    set widget_name [lang::message::lookup "" intranet-reporting-dashboard.$name_subs $name]
    set histogram_name_html "$diag.SetText(\"\",\"\", \"<B>$name</B>\");"

    # make the diagram a bit smaller and start a bit higher if the name is empty
    if {"" == $name} { 
	set histogram_name_html ""
	set diagram_y_size [expr $diagram_y_size - 25] 
	set diagram_y_start [expr $diagram_y_start - 25]
    }

    set histogram_html "
        <div style='$border position:relative;top:0px;height:[expr $diagram_y_size+20]px;width:${diagram_x_size}px;'>
	<SCRIPT Language=JavaScript type='text/javascript'>
	document.open();
	var $diag=new Diagram();
	_BFont=\"font-family:Verdana;font-weight:normal;font-size:8pt;line-height:10pt;\";
	$diag.SetFrame(0, $diagram_y_start, $diagram_x_size, $diagram_y_size);
	$diag.SetBorder(0, $max_value*1.1, $value_total_items+1, 0);
	$diag.XScale=1;
	$diag.YScale=0;
	$histogram_name_html
	$diag.Draw(\"#$bar_bg_color\", \"#$bar_text_color\", false,\"\");
	$status_html
	delete $diag;
        document.close();
	</SCRIPT>
	</div>
    "
}


# ----------------------------------------------------------------------
# Project EVA
# ---------------------------------------------------------------------

ad_proc im_dashboard_project_eva_create_audit_all {
} {
    Create project audit entries for all projects
} {
   set project_ids [db_list pids "select project_id from im_projects where parent_id is null"]
   foreach pid $project_ids {
	im_dashboard_project_eva_create_audit -project_id $pid
   }   
}

ad_proc im_dashboard_project_eva_create_audit {
    -project_id
    {-steps 50}
} {
    Creates im_projects_audit entries for the project
    by splitting the time between start_date and end_date
    in $intervals pieces and calculates new im_projects_audit
    entries for the dates based on the information of
    timesheet hours and financial documents
} {
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set default_hourly_rate [ad_parameter -package_id [im_package_cost_id] "DefaultTimesheetHourlyCost" "" "30.0"]
    set target_margin_percentage [ad_parameter -package_id [im_package_cost_id] "TargetMarginPercentage" "" "30.0"]

    # Extract max values from the project
    db_1row start_end "
	select
		max(trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2)) as project_budget_max,
		-- The cost side - thee different types - ts, bills and expenses
		max(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_max,
		max(cost_bills_cache) as cost_bills_cache_max,
		max(cost_expense_logged_cache) as cost_expense_logged_cache_max,
		-- The income side - quotes and invoices
		max(cost_invoices_cache) as cost_invoices_cache_max,
		max(cost_quotes_cache) as cost_quotes_cache_max,
		-- Delivered value
		max(cost_delivery_notes_cache) as cost_delivery_notes_cache_max
        from    im_projects_audit
        where   project_id = :project_id
    "

    set cost_max [expr $cost_timesheet_logged_cache_max + $cost_bills_cache_max + $cost_expense_logged_cache_max]
    set widget_max $cost_max
    if {$project_budget_max > $widget_max} { set widget_max $project_budget_max}

    # Get start- and end date in Julian format (as integer)
    db_1row start_end "
        select	p.*,
		to_char(start_date, 'J') as start_date_julian,
		to_char(end_date, 'J') as end_date_julian,
		to_char(now(), 'J') as now_julian,
		to_char(end_date, 'J')::integer - to_char(start_date, 'J')::integer as duration_days
        from	im_projects p
        where	project_id = :project_id
    "
    
    set cost_start_date_julian [db_string cost_start_date "
	select	to_char(min(c.effective_date), 'J')
	from	im_costs c
	where	c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
		)
    "]


    if {$cost_start_date_julian < $start_date_julian} { set start_date_julian $cost_start_date_julian }
    set modifying_action "update"
    if {$now_julian < $end_date_julian} { set end_date_julian $now_julian }
    if {$now_julian < $start_date_julian } { set start_date_julian [expr $now_julian - 10] }
    set duration_days [expr $end_date_julian - $start_date_julian]
    set increment [expr round($duration_days / $steps)]

    # Let's increase the %done value every 3-5th step
    # by a random amount, so that it reaches more or less
    # total_cost / budget
    set percent_completed_final [expr 100.0 * $cost_max / $widget_max]
    set percent_completed 0.0
    ns_log Notice "im_dashboard_project_eva_create_audit: percent_completed_final=$percent_completed_final"

    # Delete the entire history
    db_dml del_audit "delete from im_projects_audit where project_id = :project_id"

    # Loop for every day and calculate the sum of all cost types
    # per cost type
    for { set i $start_date_julian} {$i < $end_date_julian} { set i [expr $i + 1 + $increment] } {

	# Don't go further then today + 30 days
	if {$i > $now_julian + 30} { return }

	# Increase the percent_completed every 5th step
	# by a random percentage
	if {[expr rand()] < 0.2} {
	    set now_done [expr ($percent_completed_final - $percent_completed) * 5.0 / ($steps * 0.2) * rand()]
	    set now_done [expr ($now_done + abs($now_done)) / 2.0]
	    set percent_completed [expr $percent_completed + $now_done]
	    ns_log Notice "im_dashboard_project_eva_create_audit: percent_completed=$percent_completed"
	}

	set cost_timesheet_planned_cache 0.0
	set cost_expense_logged_cache 0.0
	set cost_expense_planned_cache 0.0
	set cost_quotes_cache 0.0
	set cost_bills_cache 0.0
	set cost_purchase_orders_cache 0.0
	set cost_delivery_notes_cache 0.0
	set cost_invoices_cache 0.0
	set cost_timesheet_logged_cache 0.0

	set cost_sql "
		select	sum(c.amount) as amount,
			c.cost_type_id
		from	im_costs c
		where	c.effective_date < to_date(:i, 'J') and
			c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
		group by
			cost_type_id
	"
	db_foreach costs $cost_sql {
	    switch $cost_type_id {
		 3726 { set cost_timesheet_planned_cache $amount }
		 3722 { set cost_expense_logged_cache $amount }
		 3728 { set cost_expense_planned_cache $amount }
		 3702 { set cost_quotes_cache $amount }
		 3704 { set cost_bills_cache $amount }
		 3706 { set cost_purchase_orders_cache $amount }
		 3724 { set cost_delivery_notes_cache $amount }
		 3700 { set cost_invoices_cache $amount }
		 3718 { set cost_timesheet_logged_cache $amount }
	    }
	}
	set ts_sql "
		select	sum(h.hours) as hours
		from	im_hours h
		where	h.day < to_date(:i, 'J') and
			h.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
	"
	set reported_hours_cache [db_string hours $ts_sql]

	db_dml insert "
		insert into im_projects_audit (
			modifying_action,
			last_modified,
			last_modifying_user,
			last_modifying_ip,
			project_id,
			project_name,
			project_nr,
			project_path,
			parent_id,
			company_id,
			project_type_id,
			project_status_id,
			description,
			billing_type_id,
			note,
			project_lead_id,
			supervisor_id,
			project_budget,
			corporate_sponsor,
			percent_completed,
			on_track_status_id,
			project_budget_currency,
			project_budget_hours,
			end_date,
			start_date,
			company_contact_id,
			company_project_nr,
			final_company,
			cost_invoices_cache,
			cost_quotes_cache,
			cost_delivery_notes_cache,
			cost_bills_cache,
			cost_purchase_orders_cache,
			cost_timesheet_planned_cache,
			cost_timesheet_logged_cache,
			cost_expense_planned_cache,
			cost_expense_logged_cache,
			reported_hours_cache
		) values (
			:modifying_action,
			to_date(:i,'J'),
			'[ad_get_user_id]',
			'[ns_conn peeraddr]',
			:project_id,
			:project_name,
			:project_nr,
			:project_path,
			:parent_id,
			:company_id,
			:project_type_id,
			:project_status_id,
			:description,
			:billing_type_id,
			:note,
			:project_lead_id,
			:supervisor_id,
			:project_budget,
			:corporate_sponsor,
			:percent_completed,
			:on_track_status_id,
			:project_budget_currency,
			:project_budget_hours,
			:end_date,
			:start_date,
			:company_contact_id,
			:company_project_nr,
			:final_company,
			:cost_invoices_cache,
			:cost_quotes_cache,
			:cost_delivery_notes_cache,
			:cost_bills_cache,
			:cost_purchase_orders_cache,
			:cost_timesheet_planned_cache,
			:cost_timesheet_logged_cache,
			:cost_expense_planned_cache,
			:cost_expense_logged_cache,
			:reported_hours_cache
		)
	"		    
    }
}


ad_proc im_dashboard_project_eva {
    -project_id
    { -name "" }
    { -histogram_values {} }
    { -diagram_width 300 }
    { -diagram_height 200 }
    { -font_color "000000" }
    { -diagram_color "0080FF" }
    { -dot_size 4 }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;font-size:8pt;" }
    { -bar_color "0080FF" }
    { -outer_distance 2 }
    { -left_distance 35 }
    { -bottom_distance 20 }
    { -widget_bins 5 }
} {
    Returns a formatted HTML text to display a timeline of dots
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param values Contains a list of "element" lists.
} {
    # ------------------------------------------------
    # Constants & Setup

    im_dashboard_project_eva_create_audit -project_id $project_id
    set date_format "YYYY-MM-DD HH:MI:SS"
    set today [db_string today "select to_char(now(), :date_format)"]
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set target_margin_percentage [ad_parameter -package_id [im_package_cost_id] "TargetMarginPercentage" "" "30.0"]
    if {"" == $name} { set name [db_string name "select project_name from im_projects where project_id = :project_id"] }

    # The diagram name: Every diagram needs a unique identified,
    # so that multiple diagrams can be shown on a single HTML page.
    set oname "D[expr round(rand()*1000000000.0)]"


    # ------------------------------------------------
    # Check for values that are always zero. We just let the DB calculate the sum...
    db_1row start_end "
	select
		sum(project_budget) as project_budget_sum,
		sum(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_sum,
		sum(cost_bills_cache) as cost_bills_cache_sum,
		sum(cost_expense_logged_cache) as cost_expense_logged_cache_sum,
		sum(cost_invoices_cache) as cost_invoices_cache_sum,
		sum(cost_quotes_cache) as cost_quotes_cache_sum,
		sum(cost_delivery_notes_cache) as cost_delivery_notes_cache_sum
        from    im_projects_audit
        where   project_id = :project_id
    "

    # ------------------------------------------------
    # Extract boundaries of the diagram: first and last date, maximum of the various values
    db_1row start_end "
	select  to_char(min(last_modified), :date_format) as first_date,
		to_char(max(last_modified), :date_format) as last_date,
		max(trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2)) as project_budget_max,
		-- The cost side - thee different types - ts, bills and expenses
		max(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_max,
		max(cost_bills_cache) as cost_bills_cache_max,
		max(cost_expense_logged_cache) as cost_expense_logged_cache_max,
		-- The income side - quotes and invoices
		max(cost_invoices_cache) as cost_invoices_cache_max,
		max(cost_quotes_cache) as cost_quotes_cache_max,
		-- Delivered value
		max(cost_delivery_notes_cache) as cost_delivery_notes_cache_max
        from    im_projects_audit
        where   project_id = :project_id
    "
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $first_date match year0 month0 day0 hour0 min0 sec0
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match year9 month9 day9 hour9 min9 sec9

    set cost_max [expr $cost_timesheet_logged_cache_max + $cost_bills_cache_max + $cost_expense_logged_cache_max]
    set widget_max $cost_max
    if {$project_budget_max > $widget_max} { set widget_max $project_budget_max}
    if {$cost_invoices_cache_max > $widget_max} { set widget_max $cost_invoices_cache_max }
    if {$cost_quotes_cache_max > $widget_max} { set widget_max $cost_quotes_cache_max }
    set widget_max [expr $widget_max * 1.01]
    set widget_min [expr $widget_max * -0.03]

    # ------------------------------------------------
    # Define the SQL to select the information from im_projects_audit
    set sql "
	select	*,
		to_char(last_modified, 'YYYY-MM-DD HH:MI:SS') as date,
		trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2) as project_budget_converted
	from	im_projects_audit pa
	where	project_id = :project_id
	order by
		last_modified
    "

    # ------------------------------------------------
    # Setup the parameters for every line to be drawn: Color, title, type of display

    set blue1 "00FFFF"
    set blue2 "0080FF"
    set blue3 "0000FF"
    set dark_green "408040"
    set dark_green "306030"
    set orange1 "FF8000"
    set orange2 "fecd00"
    set keys {
	date done budget
	expenses expenses_bills expenses_bills_ts
	quotes invoices
    }
    set titles { 
	"Date" "%Done" "Budget" 
	"Expenses" "Expenses+Bills" "Expenses+Bills+TS" 
	"Quotes" "Invoices"
    }
    set colors [list \
	"black" $dark_green "red" \
	$blue1 $blue2 $blue3 \
	$orange1 $orange2 \
    ]
    set show_bar_ps {
	0 0 0
	1 1 1
	0 0
    }
    set sums [list \
	1 1 $project_budget_sum \
	$cost_expense_logged_cache_sum \
	[expr $cost_expense_logged_cache_sum + $cost_bills_cache_sum] \
	[expr $cost_expense_logged_cache_sum + $cost_bills_cache_sum + $cost_timesheet_logged_cache_sum] \
	$cost_quotes_cache_sum $cost_invoices_cache_sum \
    ]

    for {set k 0} {$k < [llength $keys]} {incr k} {
	set key [lindex $keys $k]
	set title [lindex $titles $k]
	set title_hash($key) $title
	set show_bar_p [lindex $show_bar_ps $k]
	set show_bar_hash($key) $show_bar_p
	set sum [lindex $sums $k]
	set sum_hash($key) $sum
	set color [lindex $colors $k]
	set color_hash($key) $color
    }

    # ------------------------------------------------
    # Loop through all im_projects_audit rows returned
    set last_v [list]
    set last_date $first_date
    set diagram_html ""
    db_foreach project_eva $sql {

	# Fix budget as max(quotes, invoices) - target_margin
	if {"" == $cost_invoices_cache} { set cost_invoices_cache 0.0 }
	if {"" == $cost_quotes_cache} { set cost_quotes_cache 0.0 }
	if {"" == $project_budget_converted} {
	    if {$cost_quotes_cache > $cost_invoices_cache} {
set project_budget_converted [expr $cost_quotes_cache * (100.0 - $target_margin_percentage) / 100.0]
	    } else {
set project_budget_converted [expr $cost_invoices_cache * (100.0 - $target_margin_percentage) / 100.0]
	    }
	}

	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $date match year month day hour min sec
	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match last_year last_month last_day last_hour last_min last_sec

	set val_hash(date) $date
	set val_hash(done) $percent_completed
	set val_hash(budget) $project_budget_converted
	set val_hash(expenses) [expr $cost_expense_logged_cache]
	set val_hash(expenses_bills) [expr $cost_expense_logged_cache + $cost_bills_cache]
	set val_hash(expenses_bills_ts) [expr $cost_expense_logged_cache + $cost_bills_cache + $cost_timesheet_logged_cache]
	set val_hash(quotes) $cost_quotes_cache
	set val_hash(invoices) $cost_invoices_cache

	# Deal with the very first iteration.
        if {"" == [array get last_val_hash]} { array set last_val_hash [array get val_hash] }

	# Draw lines in specific order. Values drawn later will overwrite lines drawn earlier
	foreach key {expenses_bills_ts expenses_bills expenses done budget quotes invoices} {

	    # if {"" == $val_hash($key)} { continue }
	    set val [expr round(10.0 * $val_hash($key)) / 10.0]
	    set last_val [expr round(10.0 * $last_val_hash($key)) / 10.0]
	    set color $color_hash($key)
	    set title $title_hash($key)
	    set sum $sum_hash($key)
	    set show_bar_p $show_bar_hash($key)

	    if {0.0 == $sum} { continue }
	    set dot_title "$title - $val $default_currency"
	    set bar_tooltip_text "$title = $val $default_currency"
	    
	    # Show %Done as % of widget_max, not as absolute number
	    if {"done" == $key} { 
		set dot_title "$title - $val %"
		set val [expr ($val / 100.0) * $widget_max] 
		set last_val [expr 0.01 * $last_val * $widget_max] 
	    }

	    append diagram_html "
		var x = $oname.ScreenX(Date.UTC($year, $month, $day, $hour, $min, $sec));
		var last_x = $oname.ScreenX(Date.UTC($last_year, $last_month, $last_day, $last_hour, $last_min, $last_sec));
		var y = $oname.ScreenY($val);
		var last_y = $oname.ScreenY($last_val);
		new Line(last_x, last_y, x, y, \"#$color\", 1, \"$dot_title\");
		new Dot(x, y, $dot_size, 3, \"#$color\", \"$dot_title\");
	    "

	    if {$show_bar_p} {
		append diagram_html "
		new Bar(last_x, y, x, $oname.ScreenY(0), \"\#$color\", \"\", \"#000000\", \"$bar_tooltip_text\");
		"
	    }

	}
	array set last_val_hash [array get val_hash]
	set last_date $date
    }

    set y_grid_delta [expr ($widget_max - $widget_min) / $widget_bins]
    set y_grid_delta [im_diagram_round_to_next_nice_number $y_grid_delta]

    set border "border:1px solid blue; "
    set border ""

    set diagram_html "
	<div style='$border position:relative;top:0px;height:${diagram_height}px;width:${diagram_width}px;'>
	<SCRIPT Language=JavaScript>
	document.open();
	var $oname=new Diagram();

	$oname.Font=\"$font_style\";
	_BFont=\"$font_style\";

	$oname.SetFrame(
		$outer_distance + $left_distance, $outer_distance, 
		$diagram_width - $outer_distance, $diagram_height - $outer_distance - $bottom_distance
	);
	$oname.SetBorder(
		Date.UTC($year0, $month0, $day0, $hour0, $min0, $sec0),
		Date.UTC($year9, $month9, $day9, $hour9, $min9, $sec9),
		$widget_min, $widget_max
	);
	$oname.XScale=4;
	$oname.YScale=1;

	$oname.GetXGrid();
	$oname.XGridDelta=$oname.XGrid\[1\]*3;
	$oname.XGridDelta=$oname.XGrid\[1\];
	$oname.YGridDelta=$y_grid_delta;

	$oname.Draw(\"\", \"$diagram_color\", false);
	$oname.SetText(\"\",\"\", \"<B>$name</B>\");
	$diagram_html
	document.close();
	</SCRIPT>
	</div>
    "

    set legend_html ""
    foreach key {quotes invoices budget done expenses_bills_ts expenses_bills expenses} {
	set color $color_hash($key)
	set title $title_hash($key)
	set sum $sum_hash($key)
	if {0.0 == $sum} { continue }
	set url "http://www.project-open.org/documentation/portlet_intranet_reporting_dashboard"
	set alt [lang::message::lookup "" intranet-reporting-dashboard.Click_for_help "Please click on the link for help about the value shown"]
	append legend_html "
		<nobr><a href=\"$url\" target=\"_blank\">
		<font color=\"#$color\">$title</font>
		</a></nobr>
		<br>
	"
    }

    return "
	<table>
	<tr>
	<td>
		$diagram_html
	</td>
	<td>
		<table border=1>
		<tr><td>
		$legend_html
		</td></tr>
		</table>
	</td>
	</tr>
	<tr><td colspan=2>
	[lang::message::lookup "" intranet-reporting-dashboard.Project_EVA_Help "For help please hold your mouse over the diagram or click on the legend links."]
	</td></tr>
	</table>
    "
}


