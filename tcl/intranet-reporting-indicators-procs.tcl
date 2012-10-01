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

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

ad_proc -public im_indicator_section_finance {} { return 15200 }
ad_proc -public im_indicator_section_customers {} { return 15205 }
ad_proc -public im_indicator_section_pm {} { return 15210 }
ad_proc -public im_indicator_section_timesheet {} { return 15215 }
ad_proc -public im_indicator_section_trans_providers {} { return 15220 }
ad_proc -public im_indicator_section_trans_pm {} { return 15225 }
ad_proc -public im_indicator_section_kmc {} { return 15230 }
ad_proc -public im_indicator_section_hr {} { return 15235 }
ad_proc -public im_indicator_section_other {} { return 15240 }
ad_proc -public im_indicator_section_system {} { return 15245 }
ad_proc -public im_indicator_section_sla {} { return 15250 }



# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

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
    { -outer_distance 8 }
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
    set today [db_string today "select to_char(now(), 'YYYY-MM-DD HH:MI:SS')"]

    # Extract first and last date as {YYYY-MM-DD}
    set first_date [lindex [lindex $values 0] 0]
    if {"" == $first_date} { set first_date $today }
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $first_date match year0 month0 day0 hour0 min0 sec0
    set last_date [lindex [lindex $values end] 0]
    if {"" == $last_date} { set last_date $today }
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match year9 month9 day9 hour9 min9 sec9

    # Draw dots and lines from point to point.
    set last_v [lindex $values 0]
    set diagram_html ""
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
		var last_x = $oname.ScreenX(Date.UTC($last_year, $last_month, $last_day, $last_hour, $last_min, $last_sec));
		var last_y = $oname.ScreenY($last_val);

		new Line(last_x, last_y, x, y, \"$line_color\", 1, \"$name\");
		new Dot(x, y, 6, 3, \"#$dot_color\", \"$val\");
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
    { -green_color "339900" }
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
# Sweeper
# ---------------------------------------------------------------------

ad_proc -public im_indicator_evaluation_sweeper { 
} {
    Periodically runs and pre-calculates the values for the indicators
} {
    ns_log Notice "im_indicator_evaluation_sweeper: starting"

    # The first user in the system is the System Administrator...
    set current_user_id [db_string default_user "
        select  min(person_id)
        from    persons
        where   person_id > 0
    "]

    # Evaluate indicators every X hours:
    set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

    # Only evaluate indicators not related to a specific object type
    set object_type_sql "and (indicator_object_type is null OR indicator_object_type = '')"
    set object_id ""

    # No permission problems as a sweeper...
    set permission_sql ""

    # No section selected
    set section_sql ""

    set sql "
	select
		r.*,
		i.*,
		im_category_from_id(i.indicator_section_id) as section,
		ir.result
	from
		im_reports r,
		im_indicators i
		LEFT OUTER JOIN (
			select	avg(result) as result,
				result_indicator_id
			from	im_indicator_results
			where	result_date >= now() - '$eval_interval_hours hours'::interval
			group by result_indicator_id
		) ir ON (i.indicator_id = ir.result_indicator_id)
	where
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator]
		$object_type_sql
		$permission_sql
		$section_sql
	order by 
		section
    "
    db_foreach indicator_values $sql {
	ns_log Notice "im_indicator_evaluation_sweeper: indicator=$report_name"

	# Check if there was no result for the last x hours
	if {"" == $result} {
	    set result "error"
	    set error_occured [catch {set result [db_string value $report_sql]} err_msg]

	    if {$error_occured} {
		set result "<pre>$err_msg</pre>" 
	    } else {
		if {"" != $result} {
		    ns_log Notice "im_indicator_evaluation_sweeper: insert value=$result"
		    db_dml insert "
			insert into im_indicator_results (
				result_id,result_indicator_id,result_date,result
			) values (
				nextval('im_indicator_results_seq'),:report_id,now(),:result
			)
	        "
		}
	    }
	}
    }
}	


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------


ad_proc -public im_indicator_timeline_component { 
    {-current_user_id "" }
    {-object_id ""}
    {-object_type ""}
    {-indicator_section_id ""}
    {-indicator_id ""}
    {-show_description_long_p ""}
    {-show_current_value_p ""}
    {-start_date "" }
    {-end_date "" }
} {
    Returns a HTML component with the list of all timeline indicators that the user can see
} {
    ns_log Notice "im_indicator_timeline_component: start_date=$start_date, end_date=$end_date"

    if {"" == $current_user_id} { set current_user_id [ad_get_user_id] }
    set view_reports_all_p [im_permission $current_user_id "view_reports_all"]
    set add_reports_p [im_permission $current_user_id "add_reports"]
    set wiki_url "http://www.project-open.org/en"

    # Evaluate indicators every X hours:
    set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

    if {"" == $show_description_long_p && "" != $indicator_section_id} {
	set show_description_long_p 0
	set show_current_value_p 0
    }

    set object_type_sql "and (indicator_object_type is null OR indicator_object_type = '')"
    if {"" != $object_type} { set object_type_sql "and lower(indicator_object_type) = lower(:object_type)" }

    set permission_sql "and 't' = im_object_permission_p(r.report_id, :current_user_id, 'read')"
    if {$view_reports_all_p} { set permission_sql "" }

    set section_sql "and i.indicator_section_id = :indicator_section_id"
    if {"" == $indicator_section_id} { set section_sql "" }

    db_multirow -extend {report_view_url edit_html value_html history_html} reports get_reports "
	select
		r.*,
		i.*,
		im_category_from_id(i.indicator_section_id) as section,
		ir.result
	from
		im_reports r,
		im_indicators i
		LEFT OUTER JOIN (
			select	avg(result) as result,
				result_indicator_id
			from	im_indicator_results
			where	result_date >= now() - '$eval_interval_hours hours'::interval
			group by result_indicator_id
		) ir ON (i.indicator_id = ir.result_indicator_id)
	where
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator]
		$object_type_sql
		$permission_sql
		$section_sql
	order by 
		section
    " {
	set report_view_url [export_vars -base "view" {indicator_id return_url}]
	set report_edit_url [export_vars -base "new" {indicator_id}]
	set perms_url [export_vars -base "perms" {{object_id $indicator_id}}]
	set delete_url [export_vars -base "delete" {indicator_id return_url}]
	set edit_html "
		[im_gif "help" [ns_quotehtml $report_description]]<br>
		<a href=\"$report_edit_url\">[im_gif "wrench"]</a><br>
		<a href=\"$perms_url\">[im_gif "lock"]</a><br>
	<!--	<a href=\"$delete_url\">[im_gif "cancel"]</a> -->
	"

	regsub -all " " $report_name "_" indicator_name_mangled
	set help_url "$wiki_url/indicator_[string tolower $indicator_name_mangled]"
	set report_description "
	$report_description
	<a href=\"$help_url\">[lang::message::lookup "" intranet-reporting-indicators.More_dots "more..."]</a><br>
        "

	if {"" == $result} {
	    set substitution_list [list user_id $current_user_id object_id $object_id]
	    set result [im_indicator_evaluate \
			    -report_id $report_id \
			    -object_id $object_id \
			    -report_sql $report_sql \
			    -substitution_list $substitution_list \
			   ]
	}	
	
	set value_html $result
	set history_html ""
	
	set start_date_sql ""
	set end_date_sql ""
	if {"" != $start_date} { set start_date_sql "and result_date >= :start_date" }
	if {"" != $end_date} { set end_date_sql "and result_date < :end_date" }

	if {"error" != $result && "" != $result} {
	    
	    set indicator_sql "
	        select	result_date, result
	        from	im_indicator_results
	        where	result_indicator_id = :report_id
			$start_date_sql
			$end_date_sql
	        order by result_date
            "
	    set values [db_list_of_lists results $indicator_sql]
	
	    set min $indicator_widget_min
	    if {"" == $min} { set min 1000000 }
	    set max $indicator_widget_max
	    if {"" == $max} { set max -1000000 }
	    
	    foreach vv $values { 
		set v [lindex $vv 1]
		if {$v < $min} { set min $v }
		if {$v > $max} { set max $v }
	    }
	    
	    set history_html ""
	    set history_html [im_indicator_timeline_widget \
				  -name $report_name \
				  -values $values \
				  -widget_min $min \
				  -widget_max $max \
				 ]
	}
	
    }

    # ------------------------------------------------------
    # Create List 

    set elements_list {}

    # Show the section only if it's not explicitely specified...
    if {"" == $indicator_section_id} {
    	lappend elements_list \
	section {
	    label "Section"
	    display_template {
		@reports.section@
	    }
	}
    }
	
    lappend elements_list \
	name {
	    label "Name"
	    display_template {
		<a href=@reports.report_view_url@>@reports.report_name@</a>
	    }
	}
    
    
    if {0 != $show_current_value_p} {
       lappend elements_list \
	value {
	    label "Value"
	    display_template {
		@reports.value_html;noquote@
	    }
	}
    }

    lappend elements_list \
	history {
	    label "History"
	    display_template {
		@reports.history_html;noquote@
	    }
	}
    
    if {$add_reports_p} {
	lappend elements_list \
	    edit {
		label "[im_gif wrench]"
		display_template {
		    @reports.edit_html;noquote@
		}
	    }
    }
    
   if {0 != $show_description_long_p} {
        lappend elements_list \
	report_description {
	    label "Description"
	    display_template {
		@reports.report_description;noquote@
	    }
	}
    }
    
    
    template::list::create \
        -name indicator_list \
        -multirow reports \
        -key menu_id \
        -elements $elements_list \
        -filters {
	    return_url
        }
    
    
    # Compile and execute the formtemplate if advanced filtering is enabled.
    eval [template::adp_compile -string {<listtemplate name="indicator_list"></listtemplate>}]
    set list_html $__adp_output

    return $list_html
}




ad_proc -public im_indicator_home_page_component { 
    {-module "asdf" }
} {
    Returns a HTML component with the list 
    of all indicators that the user can see
} {
    set params [list \
	[list user_id [ad_get_user_id]] \
	[list module $module] \
	[list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-reporting-indicators/www/indicator-home-component"]
    return [string trim $result]
}




# ----------------------------------------------------------------------
# Indicator Evaluation
# ---------------------------------------------------------------------

ad_proc -public im_indicator_evaluate {
    -report_id
    -report_sql
    { -object_id "" }
    { -substitution_list {} }
} {
    Evaluates the specified indicator.
    @param substitution_list A key - value list of values to be substituted in the indicator.
    @param object_id Object ID for evaluating indicators related to an object type.
} {
    # -------------------------------------------------------
    # Append form vars to the substitution list
    set form_vars [ns_conn form]
    foreach form_var [ad_ns_set_keys $form_vars] {
	set form_val [ns_set get $form_vars $form_var]
	lappend substitution_list $form_var
	lappend substitution_list $form_val
    }

    # -------------------------------------------------------
    # Append vars from object_id if set
    if {"" != $object_id} {
	# Get the SQL to extract all values from the object
	set object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""]
	set sql [im_rest_object_type_select_sql -rest_otype $object_type]

	# Get the list of index columns of the object's various tables.
	set index_columns [im_rest_object_type_index_columns -rest_otype $object_type]

	# Execute the sql. As a result we get a result_hash with keys corresponding
	# to table columns and values
	array set result_hash {}
	set rest_oid $object_id
	db_with_handle db {
	    set selection [db_exec select $db query $sql 1]
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

    set report_sql_subst [lang::message::format $report_sql $substitution_list]

    # Evaluate the indicator
    set result "error"
    set error_occured [catch {
	set result [db_string value $report_sql_subst]
    } err_msg]
    
    if {$error_occured} { 
#	ad_return_complaint 1 "<pre>[join $substitution_list "\n"]\n\n$err_msg\n\n$report_sql_subst</pre>"
	set report_description "<pre>$err_msg</pre>" 
	set result $err_msg
    } else {

	if {"" != $result} {
	    db_dml insert "
				insert into im_indicator_results (
					result_id,
					result_indicator_id,
					result_date,
					result
				) values (
					nextval('im_indicator_results_seq'),
					:report_id,
					now(),
					:result
				)
	    "
	}

    }
    return $result
}


