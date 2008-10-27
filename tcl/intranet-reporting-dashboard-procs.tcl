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

    regsub -all " " $name "_" name_subs
    set widget_name [lang::message::lookup "" intranet-reporting-dashboard.$name_subs $name]
    return [im_dashboard_histogram -name $widget_name -values $values]
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

    set name [lang::message::lookup "" intranet-reporting-dashboard.Project_Queue "Project Queue"]
    return [im_dashboard_histogram -name $name -values $values]

}


# ----------------------------------------------------------------------
# Define a color bar from red to blue or similar...
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_colors { 
    { -max_entries 8 }
    { -start_color "0080FF" }
    { -end_color "FF8000" }
} {
    Returns an array with color codes from 0.. $max_entries
    (max_entries+1 in total)
} {
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
    { -start_color "0080FF" }
    { -end_color "FF8000" }
    { -font_color "000000" }
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
	-values {{Abc 10} {Bcde 20} {Cdefg 30} {Defg 25}} \
        -start_color "0080FF" \
	-end_color "80FF80"]</pre>

			       
} {
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
        <SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT> 
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
    { -bar_color "0080FF" }
    { -outer_distance 20 }
    { -diagram_width 400 }
    { -font_color "000000" }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;" }
} {
    Returns a formatted HTML text to display a histogram chart
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.

    Short example:
	<pre>set histogram_chart [im_dashboard_histogram \
        -values {{Potential 10} {Quoting 5} {Open 5} {Invoicing 6}} \
        -bar_color "0080FF" \
	]</pre>
} {
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

    set count 1
    foreach v $values {

	set bar_title [lindex $v 0]
	set vals [lrange $v 1 end]

	append status_html "
		new Bar(
			1+$diag.ScreenX(0), $diag.ScreenY($count), 
			1+$diag.ScreenX($max_value), $bar_width + $diag.ScreenY($count),
			\"\", \"$bar_title\", \"#000000\", \"$bar_title\",
			\"\", \"\", \"\", \"left\"
		);
	"
	incr count

	foreach cnt $vals {
	    append status_html "
		new Bar(
			1+$diag.ScreenX(0), $diag.ScreenY($count), 
			1+$diag.ScreenX($cnt), $bar_width + $diag.ScreenY($count),
			\"#0080FF\", \"&nbsp;\", \"#000000\", \"&nbsp;\", \"\"
		);
            "
	    incr count
	}
    }

    set border "border:1px solid blue; "
    set border ""

    set histogram_html "
	<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>
        <div style='$border position:relative;top:0px;height:[expr $diagram_y_size+50]px;width:${diagram_x_size}px;'>
	<SCRIPT Language=JavaScript>

	document.open();

	var $diag=new Diagram();
	_BFont=\"font-family:Verdana;font-weight:normal;font-size:8pt;line-height:10pt;\";
	$diag.SetFrame(0, 25, $diagram_x_size, $diagram_y_size);
	$diag.SetBorder(0, $max_value*1.1, $value_total_items+1, 0);
	$diag.XScale=1;
	$diag.YScale=0;
	$diag.SetText(\"\",\"\", \"<B>$name</B>\");
	$diag.Draw(\"#FFFFFF\", \"#004080\", false,\"Click on a bar to get the phone number\");
	$status_html
	delete $diag;

        document.close();

	</SCRIPT>
	</div>
    "
}




