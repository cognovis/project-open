



ad_proc im_dashboard_timeline {
    { -name "Timeline" }
    { -values {} }
    { -diagram_width 600 }
    { -diagram_height 200 }
    { -font_color "000000" }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;" }
    { -bar_color "0080FF" }
    { -outer_distance 20 }
} {
    Returns a formatted HTML text to display a timeline of stacked bars
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param values Contains a list of "element" lists.
		  Each Element list consists of:
			1. Date in YYYY-MM-DD notation
			2. Value #1
			3. Value #2
			...
} {
    # How many values in total
    set num_values [llength values]
    set bar_width [expr round(4.0 / 5.0 * $diagram_width / $num_values)]
    set bar_width 6
    set bar_distance [expr round(1.0 / 5.0 * $diagram_width / $num_values)]
    
    # Extract first and last date as {YYYY MM DD}
    set first_date [lindex [lindex $values 0] 0]
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $first_date match year0 month0 day0 hour0 min0 sec0
    set last_date [lindex [lindex $values end] 0]
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match year9 month9 day9 hour9 min9 sec9

    # Max # items and value
    set max_value 0
    set value_total_items 0
    set value_data_sets 0

    foreach v $values {
	incr value_data_sets
	set value_total_items [expr $value_total_items + [llength $v]]
	set v_vals [lrange $v 1 end]
	foreach v_val $v_vals {
	    if {$v_val > $max_value} { set max_value $v_val}
	}
    }
    set max_value [expr $max_value * 1.1]

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

	    append status_html "
		var x = D1.ScreenX(Date.UTC($year, $month, $day, $hour, $min, $sec));
		var y = D1.ScreenY($val);
		var last_x = D1.ScreenX(Date.UTC($year, $last_month, $last_day, $last_hour, $last_min, $last_sec));
		var last_y = D1.ScreenY($last_val);

		new Line(last_x, last_y, x, y, \"#cc9966\", 2, \"temperature\");
		new Dot(x, y, 8, 3, \"#FF0000\", \"$val\");
	    "

	    incr val_count
	}
	set last_v $v
    }


    set border "border:1px solid blue; "
    set border ""

    set histogram_html "
	<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>
	<div style='$border position:relative;top:0px;height:[expr $diagram_height+40]px;width:${diagram_width}px;'>
	<SCRIPT Language=JavaScript>
	document.open();
	var D1=new Diagram();
	_BFont=\"font-family:Verdana;font-weight:normal;font-size:8pt;line-height:10pt;\";
	D1.SetFrame($outer_distance + 20, $outer_distance, $diagram_width - $outer_distance, $diagram_height - $outer_distance);
	D1.SetBorder(
		Date.UTC($year0, $month0, $day0, $hour0, $min0, $sec0),
		Date.UTC($year9, $month9, $day9, $hour9, $min9, $sec9),
		0, $max_value
	);
	D1.XScale=4;
	D1.YScale=1;
	D1.Draw(\"\", \"#004080\", false);
	D1.SetText(\"\",\"\", \"<B>Project Queue</B>\");
	$status_html
	document.close();
	</SCRIPT>
	</div>
    "
}


set hours_sql "
	select	sum(hours) as hours,
		day::date as day 
	from 	im_hours 
	group by day::date
	order by day
"

set lifecycle_sql "
	select
		last_modified,
		project_status_id,
		project_budget_hours,
		reported_hours_cache,
		project_budget,
		cost_invoices_cache,
		cost_quotes_cache,
		cost_bills_cache,
		cost_purchase_orders_cache,
		cost_timesheet_logged_cache,
		cost_expense_logged_cache
	from 
		im_projects_audit
	where 
		project_id = 54316 
	order by 
		last_modified;
"

set values [list]
db_foreach lifecycle $lifecycle_sql {
    lappend values [list $last_modified $reported_hours_cache $project_budget_hours]
}
set histogram_html [im_dashboard_timeline -values $values]
