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
	$oname.YGridDelta=$y_grid_delta;

	$oname.Draw(\"\", \"$diagram_color\", false);
	$oname.SetText(\"\",\"\", \"<B>$name</B>\");
	$diagram_html
	document.close();
	</SCRIPT>
	</div>
    "
}

