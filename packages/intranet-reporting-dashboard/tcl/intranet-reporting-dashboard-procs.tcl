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

# ----------------------------------------------------------------
# Dereferencing Function
# ----------------------------------------------------------------

ad_proc -public v {
    var_name
    {undef "-"}
} {
    Acts like a "$" to evaluate a variable, but
    returns "-" if the variable is not defined
    instead of an error.
} {
    upvar $var_name var
    if [exists_and_not_null var] { return $var }
    return $undef
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

    if {"" == $start_date} { set start_date [db_string start "select to_char(now()::date-10000, 'YYYY-MM-01')"] }
    if {"" == $end_date} { set end_date [db_string start "select to_char(now()::date+60, 'YYYY-MM-01')"] }

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
# Generic Status Change Matrix
# ---------------------------------------------------------------------


ad_proc -public im_dashboard_status_matrix {
    -sql:required
    -status_list:required
    { -description "" }
    { -cache_seconds 3600 }
    { -border_color "" }
    { -background_color "" }
    { -text_color "" }
    { -max_category_len 3 }
} {
    Returns a matrix that shows how many objects have changed their status
    in the given time period. 
    @param sql: A SQL statement returning the three columns "cnt", "old_status_id" 
                and "new_status_id".
    @param status_list: An order list of the IDs of states to be shown.
    @param description: A description text to appear below the matrix.
    @param cache_seconds: How long should the results of the SQL evaluation be cached? Default is 3600 (1 hour).
    @param border_color: The HTML color of the table border.
    @param background_color: The HTML color of the table background.
    @param text_color: The HTML color of the matrix text.
    @param max_category_len: Should we shorten the names of the states in the 
           table header? Set 0 to disable. Set to 3 for a narrow matrix. Default is 3.
} {
    if {"" == $border_color} { set border_color [im_dashboard_color -type bar_color] }
    if {"" == $text_color} { set text_color [im_dashboard_color -type bar_text_color] }
    if {"" == $background_color} { set background_color [im_dashboard_color -type bar_bg_color] }

    # Cache calculating the matrix of data because it could be 
    # relatively slow when using the audit package
    set data_matrix [util_memoize [list im_dashboard_status_matrix_helper -sql $sql] $cache_seconds]
    array set matrix_hash $data_matrix

    # Format the table header
    set from_to_msg [lang::message::lookup "" intranet-reporting_dashboard.From_to "From \\ To"]
    set new_msg [lang::message::lookup "" intranet-reporting_dashboard.Status_New_Object "&lt;New&gt;"]
    set html "<table border=2 bordercolor=$border_color>\n"
    append html "<tr><td><b>$from_to_msg</b></td>\n"
    foreach stid $status_list {
	set status [im_category_from_id -empty_default $new_msg $stid]
	if {0 != $max_category_len} { 
	    set status [string range $status 0 [expr $max_category_len-1]] 
	}
	append html "<td><b>$status</b></td>\n"
    }
    append html "</tr>\n"

    # Format the table body
    set from_status_list [linsert $status_list 0 0]
    foreach from_stid $from_status_list {
	append html "<tr><td><b>[im_category_from_id -empty_default $new_msg $from_stid]</b></td>\n"
	foreach to_stid $status_list {
	    set key "$from_stid-$to_stid"
	    set val [v matrix_hash($key) ""]
	    append html "<td>$val</td>\n"
	}
	append html "</tr>\n"
    }
    if {"" != $description} {
	set colspan [expr [llength $status_list] + 1]
	append html "<tr><td colspan=$colspan align=center>\n$description\n</td></tr>\n"
    }
    append html "</table>\n"

    return $html
}

ad_proc -public im_dashboard_status_matrix_helper {
    -sql:required
} {
    Evaluates an SQL that returns cnt, old_status_id and new_status_id
    and returns the values as list suitable for a hash array with 
    key = $old_status_id-$new_status_id
} {
    array set hash {}
    db_foreach im_dashboard_status $sql {
	if {"" == $old_status_id} { set old_status_id 0 }
	if {"" == $new_status_id} { set new_status_id 0 }
	set key "$old_status_id-$new_status_id"
	set hash($key) $cnt
    }
    return [array get hash]
}


# ----------------------------------------------------------------------
# Generic Histogram
# ---------------------------------------------------------------------

ad_proc -public im_dashboard_histogram_sql {
    -sql:required
    { -object_id "" }
    { -menu_label "" }
    { -name "" }
    { -diagram_width 400 }
    { -restrict_to_object_type_id 0 }
} {
    Returns a dashboard component.
    Requires a SQL statement like 
    "select im_category_from_id(project_type_id), count(*) from im_projects group by project_type_id"
    @param object_id ID of a container object.
    @param restrict_to_object_type_id Show this widget only in objects of a specific type
} {
    # -------------------------------------------------------
    # Pull out the object type and sub-type
    set object_type ""
    set object_subtype_id ""
    if {"" != $object_id && 0 != $object_id} {
	im_security_alert_check_integer -location "im_dashboard_histogram_sql" -value $object_id
	set object_type [util_memoize "db_string otype {select object_type from acs_objects where object_id = $object_id} -default {}"]
	set object_subtype_id [util_memoize "db_string osubtype {select im_biz_object__get_type_id($object_id)} -default {}" 60]
    }

    # -------------------------------------------------------
    # Check if this portlet should only apply to a specific object sub-type
    if {"" != $object_id && 0 != $object_id && "" != $restrict_to_object_type_id && 0 != $restrict_to_object_type_id} {
	if {$object_subtype_id != $restrict_to_object_type_id} { 
	    ns_log Notice "im_dashboard_histogram_sql: Skipping portlet because object_subtype_id=$object_subtype_id != $restrict_to_object_type_id"
	    return "" 
	}
    }

    # -------------------------------------------------------
    # The substitution list defines variable-key tuples that
    # the SQL can use.
    set substitution_list {}
    lappend substitution_list object_id
    lappend substitution_list $object_id

    # -------------------------------------------------------
    # Append vars from object_id if set
    if {"" != $object_id} {
	# Get the SQL to extract all values from the object
	set object_sql [im_rest_object_type_select_sql -rest_otype $object_type]

	# Get the list of index columns of the object's various tables.
	set index_columns [im_rest_object_type_index_columns -rest_otype $object_type]

	# Execute the sql. As a result we get a result_hash with keys corresponding
	# to table columns and values
	array set result_hash {}
	set rest_oid $object_id
	db_with_handle db {
	    set selection [db_exec select $db query $object_sql 1]
	    while { [db_getrow $db $selection] } {
		set col_names [ad_ns_set_keys $selection]
		set this_result [list]
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    set var [lindex $col_names $i]
		    set val [ns_set value $selection $i]
		    lappend substitution_list $var
		    lappend substitution_list $val
		}
	    }
	}
	db_release_unused_handles
    }

    set sql_subst [lang::message::format $sql $substitution_list]

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

    set values [db_list_of_lists dashboard_historgram $sql_subst]

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

    set status_html ""
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

    if {"" == $status_html} {
	# SQL didn't return any rows
	# So don't show the diagram at all
	set histogram_html ""
    }

    return $histogram_html
}

