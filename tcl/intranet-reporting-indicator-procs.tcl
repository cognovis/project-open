# /packages/intranet-reporting-indicators/tcl/intranet-reporting-indicator-procs.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Reporting Indicators
    @author frank.bergmann@project-open.com
}

ad_proc im_diagram_date2seconds { year month day hour min sec } {
	Convert data format into seconds since 1st of January 0000
} {
	set result [expr $year*365+$month*30+$day]
	set result [expr $result*24 + $hour*3600 + $min*60 + $sec]
	return [expr $result * 1000]
}


ad_proc im_diagram_round_to_next_nice_number { delta } {
    Round the value to the next full "nice" number
} {
    # Transform delta in the space between 0 and 0.99
    set factor 1
    while {$delta >= 1} {
	set factor [expr $factor * 10.0]
	set delta [expr $delta / 10.0]
    }

    if {$delta < 0.1} { return [expr round($factor * 0.1)] }
    if {$delta < 0.2} { return [expr round($factor * 0.2)] }
    if {$delta < 0.5} { return [expr round($factor * 0.5)] }
    return [expr round($factor * 1.0)]
}


ad_proc im_indicator_timeline_widget {
    -name
    { -values {} }
    { -histogram_values {} }
    { -diagram_width 200 }
    { -diagram_height 80 }
    { -font_color "000000" }
    { -line_color "0080FF" }
    { -diagram_color "0080FF" }
    { -dot_color "FF0000" }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;font-size:8pt;" }
    { -bar_color "0080FF" }
    { -outer_distance 2 }
    { -left_distance 35 }
    { -bottom_distance 20 }
    { -widget_min 0 }
    { -widget_max 100 }
    { -widget_bins 5 }
} {
    Returns a formatted HTML text to display a timeline of dots
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param values Contains a list of "element" lists.
		  Each Element list consists of:
			1. Date in YYYY-MM-DD notation
			2. Value #1
			3. Value #2
			...
} {
    set oname "D[expr round(rand()*10000000)]"

    # Extract first and last date as {YYYY MM DD}
    set first_date [lindex [lindex $values 0] 0]
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $first_date match year0 month0 day0 hour0 min0 sec0
    set last_date [lindex [lindex $values end] 0]
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match year9 month9 day9 hour9 min9 sec9

    # Draw dots and lines from point to point.
    set last_v [lindex $values 0]
    foreach v $values {

	set date [lindex $v 0]
	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $date match year month day hour min sec
	set last_date [lindex $last_v 0]
	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match last_year last_month last_day last_hour last_min last_sec

	set vals [lrange $v 1 end]
	set last_vals [lrange $last_v 1 end]
	set val_count 0
	foreach val $vals {
	    set last_val [lindex $last_vals $val_count]
	    append diagram_html "
		var x = $oname.ScreenX(Date.UTC($year, $month, $day, $hour, $min, $sec));
		var y = $oname.ScreenY($val);
		var last_x = $oname.ScreenX(Date.UTC($year, $last_month, $last_day, $last_hour, $last_min, $last_sec));
		var last_y = $oname.ScreenY($last_val);

		new Dot(x, y, 6, 1, \"$dot_color\", \"$val\");
		new Line(last_x, last_y, x, y, \"$line_color\", 1, \"$name\");
	    "
	    incr val_count
	}
	set last_v $v
    }

    set hist_html ""
    if {[llength $histogram_values] > 0} {

	# For the v-size of the bar just divide the diagram space by the number of bins.
	# We asume that the histogram data are calculated correctly within the range of the diagram...
	set bar_height [expr ($diagram_height - $outer_distance - $bottom_distance) / [llength $histogram_values] - 2]
	
	foreach v $histogram_values {
	    
	    set vy [lindex $v 0]
	    set vperc [lindex $v 1]
	    
	    # Display the percent text in an invisible bar
	    append hist_html "
		var left_x = 3 + $oname.ScreenX(Date.UTC($year9, $month9, $day9, $hour9, $min9, $sec9));
		var right_x = left_x + 20;
		var bot_y = $oname.ScreenY($vy);
		var top_y = bot_y - $bar_height;
                new Bar(left_x, top_y, right_x, bot_y, \"\", \"${vperc}%\", \"$diagram_color\");
            "

	    # Draw the bar
	    append hist_html "
		var left_x = 30 + $oname.ScreenX(Date.UTC($year9, $month9, $day9, $hour9, $min9, $sec9));
		var right_x = left_x + $vperc;
		var bot_y = $oname.ScreenY($vy);
		var top_y = bot_y - $bar_height;
                new Bar(left_x, top_y, right_x, bot_y, \"#0080FF\", \"&nbsp;\", \"#000000\");
            "
	}
    }

    set y_grid_delta [expr ($widget_max - $widget_min) / $widget_bins]
    set y_grid_delta [im_diagram_round_to_next_nice_number $y_grid_delta]

    set border "border:1px solid blue; "
    set border ""

    set histogram_html "
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
	$hist_html
	document.close();
	</SCRIPT>
	</div>
    "

    return $histogram_html
}






# ----------------------------------------------------------------------
# Horizontal Bar with yellow-green-red display
# ---------------------------------------------------------------------


ad_proc im_indicator_horizontal_bar {
    -name
    -value
    -widget_min
    -widget_max
    { -widget_min_red "" }
    { -widget_min_yellow "" }
    { -widget_max_yellow "" }
    { -widget_max_red "" }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:6pt;font-size:7pt;" }   
    { -widget_bar_size "4" }
    { -widget_value_bar_size "6" }
    { -widget_color "0080FF" }
    { -value_color "000000" }
    { -red_color "FF0000" }
    { -yellow_color "FFD000" }
    { -green_color "00D000" }
    { -white_color "FFFFFF" }
    { -widget_width 200 }
    { -widget_height 30 }
    { -bottom_distance 12 }
    { -outer_distance 2 }
    { -left_distance 5 }
} {
    Returns a formatted HTML text to display a timeline of dots
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param value Value of the indicator
} {
    # Sanity checks
    if {"" == $value} { return "" }

    if {"" == $widget_min} { set widget_min 0 }
    if {"" == $widget_max} { set widget_max 10 }

    if {[string is double $value]} {
	if {$value < $widget_min} { set widget_min $value }
	if {$value > $widget_max} { set widget_max $value }
    }

    # Create a "unique" diagram name for each diagram, in order to display
    # several diagrams on the same page.
    set o "D[expr round(rand()*10000000)]"

    # Default values
    set dist [expr ($widget_max - $widget_min) / 50]
    set dist 0
    if {"" == $widget_min_red} { set widget_min_red [expr $widget_min+$dist] }
    if {"" == $widget_min_yellow} { set widget_min_yellow [expr $widget_min_red+$dist] }
    if {"" == $widget_max_red} { set widget_max_red [expr $widget_max-$dist] }
    if {"" == $widget_max_yellow} { set widget_max_yellow [expr $widget_max_red-$dist] }

    set border "border:1px solid blue; "
    set border ""

    set histogram_html "
	<div style='$border position:relative;top:0px;height:${widget_height}px;width:${widget_width}px;'>
	<SCRIPT Language='JavaScript'>
	document.open();
	var $o = new Diagram();
	$o.Font = \"$font_style\";
	$o.SetFrame(
		$outer_distance + $left_distance, $outer_distance, 
		$widget_width - $outer_distance, $widget_height - $outer_distance - $bottom_distance
	);
	$o.SetBorder($widget_min, $widget_max, 0, 2);
	$o.XScale = 1;
	$o.YScale = 0;
	var v = $o.ScreenY(1);
	$o.Draw(\"#$white_color\", \"$widget_color\", false);
	$o.SetText(\"\",\"\", \"<B>$name</B>\");
	
	new Bar($o.ScreenX($widget_min), v-$widget_bar_size, $o.ScreenX($widget_min_red), v+$widget_bar_size, \"#$red_color\", \"\", \"#$white_color\", \"Red\");
	new Bar($o.ScreenX($widget_min_red), v-$widget_bar_size, $o.ScreenX($widget_min_yellow), v+$widget_bar_size, \"#$yellow_color\", \"\", \"#$white_color\", \"Yellow\");
	new Bar($o.ScreenX($widget_min_yellow), v-$widget_bar_size, $o.ScreenX($widget_max_yellow), v+$widget_bar_size, \"#$green_color\", \"\", \"#$white_color\", \"Green\");
	new Bar($o.ScreenX($widget_max_yellow), v-$widget_bar_size, $o.ScreenX($widget_max_red), v+$widget_bar_size, \"#$yellow_color\", \"\", \"#$white_color\", \"Yellow\");
	new Bar($o.ScreenX($widget_max_red), v-$widget_bar_size, $o.ScreenX($widget_max), v+$widget_bar_size, \"#$red_color\", \"\", \"#$white_color\", \"Red\");

	new Bar($o.ScreenX($value)-1, v-$widget_value_bar_size, $o.ScreenX($value)+1, v+$widget_value_bar_size, \"#$value_color\", \"\", \"#$white_color\", \"Black\");

	document.close();
	</SCRIPT> 
	</div>
    "

    return $histogram_html
}



# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_indicator_home_page_component { } {
    Returns a HTML component with the list 
    of all indicators that the user can see
} {
    set params [list \
	[list user_id [ad_get_user_id]] \
	[list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-reporting-indicators/www/indicator-home-component"]
    return [string trim $result]
}
