# /intranet-riskmanagement/lib/risk-project-component.tcl
#
# Variables from page:
#
# project_id
# risk_status_id
# risk_type_id
# start_date
# end_date
# risk_ids

if {![info exists view_name] || "" == $view_name} { set view_name "im_risk_list_short" }
set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

set cell_width 15

set return_url [im_url_with_query]

# ---------------------------------------------------------
# Define constants for classifying risks
# ---------------------------------------------------------

set project_budget [db_string budget "
	select	project_budget
	from	im_projects
	where	project_id = :project_id
" -default 0]

# Classifiers for impact and probability.
# Each classified starts with 0 and ends at "ininite"
set impact_classifier [list 0 5 10 20 30 100]
set probab_classifier [list 0 5 10 20 30 100]

set probab_classifier_values $probab_classifier
set impact_classifier_values {}
foreach i $impact_classifier { 
    catch {
	lappend impact_classifier_values [expr 1.0 * $project_budget * $i / 100.0] 
    }
}



ad_proc im_risk_chart_classify {
    -value:required
    -classifier:required
} {
    Classifies value into the range of values in classifier.
    @param value The value to classify
    @classifier A list of values excluding "0" at the beginning and "infinite" at the end
    @returns Integer in the range of 0 .. end, indicating the position of value in the classified
} {
    # Append start and end of scale
    set result ""
    for {set i 0} {$i <= [llength $classifier]} {incr i} {
	set low [lindex $classifier $i]
	set high [lindex $classifier [expr $i+1]]
	if {$value >= $low && $value <= $high} { 
	    set result $i
	    break
	}
    }
    
    if {"" == $result} {
	if {$value >= $high} { 
	    set result [expr [llength $classifier]-2]
	}
    }

    return $result
}

ad_proc im_risk_chart_bg_color {
    -x:required
    -y:required
    -max:required
} {
    Returns a suitable background color for x/y coordinates
} {
    set sum [expr $x + $y]
    switch $sum {
	0 { return "#00FF00" }
	1 { return "#80FF80" }
	2 { return "#C0FFC0" }
	6 { return "#FFC0C0" }
	7 { return "#FF8080" }
	8 { return "#FF0000" }
	default {return "#FFFFFF" }
    }
}

# ---------------------------------------------------------
# View Columns
# ---------------------------------------------------------

set column_headers [list]
set column_vars [list]
set admin_links [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]

set column_sql "
	select	*
	from	im_view_columns
	where	view_id = :view_id
		and group_id is null
	order by sort_order
"
set col_span 0
set table_header_html ""
db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	lappend admin_links "<a href=[export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}] target=\"_blank\"><span class=\"icon_wrench_po\">[im_gif wrench]</span></a>"

	set admin_url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url {form_mode edit}}]
	set admin_html "<a href='$admin_url'>[im_gif wrench]</a>"
	append table_header_html "<td class=rowtitle>$column_name $admin_html</td>\n"
	
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }
    incr col_span
}

set table_header_html "<tr class=rowtitle>$table_header_html</tr>\n"



# ---------------------------------------------------------
# List the risks
# and format the risk chart
# ---------------------------------------------------------

set criteria {}
if {[info exists project_id] && "" != $project_id && 0 != $project_id} { lappend criteria "r.risk_project_id = :project_id" }
if {[info exists risk_status_id] && "" != $risk_status_id && 0 != $risk_status_id} { lappend criteria "r.risk_status_id = :risk_status_id" }
if {[info exists risk_type_id] && "" != $risk_type_id && 0 != $risk_type_id} { lappend criteria "r.risk_type_id = :risk_type_id" }
if {[info exists start_date] && "" != $start_date && 0 != $start_date} { lappend criteria "o.creation_date >= :start_date" }
if {[info exists end_date] && "" != $end_date && 0 != $end_date} { lappend criteria "o.creation_date <= :end_date" }
if {[info exists risk_ids] && "" != $risk_ids && 0 != $risk_ids} { lappend criteria "r.risk_id in ([join $risk_ids ","])" }
set where_clause [join $criteria " and\n\t\t"]
if {[llength $criteria] > 0} { set where_clause "and $where_clause" }

set risk_sql "
	select	r.*,
		im_category_from_id(r.risk_type_id) as risk_type,
		im_category_from_id(r.risk_status_id) as risk_status
	from	im_risks r,
		acs_objects o
	where	r.risk_id = o.object_id 
		$where_clause
	order by risk_probability_percent * risk_impact DESC;
"

set ctr 0
set table_body_html ""
set risk_chart_html ""
array set chart_hash {}
array set chart_ids_hash {}
db_foreach risks $risk_sql {

    # Format columns for the list view
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
        append row_html "\t<td valign=top><nobr>"
        set cmd "append row_html $column_var"
        eval "$cmd"
        append row_html "</nobr></td>\n"
    }
    append row_html "</tr>\n"
    append table_body_html $row_html

    # Classify risks for the 3x3 risk overview
    set impact_class [im_risk_chart_classify -value $risk_impact -classifier $impact_classifier_values]
    set probab_class [im_risk_chart_classify -value $risk_probability_percent -classifier $probab_classifier_values]
    if {"" == $impact_class || "" == $probab_class} {
	ad_return_complaint 1 "impact=$impact_class, prob=$probab_class"
    }
    set key "$impact_class-$probab_class"

    # Chart Hash - Number of risks in the cell
    set v 0
    if {[info exists chart_hash($key)]} { set v $chart_hash($key) }
    set v [expr $v + 1]
    set chart_hash($key) $v

    # Chart risk_ids Hash - The IDs of the risks in the cell
    set v {}
    if {[info exists chart_ids_hash($key)]} { set v $chart_ids_hash($key) }
    lappend v $risk_id
    set chart_ids_hash($key) $v
    
    incr ctr
}

# Format the risk summary chart
set risk_chart_header "<td width=20></td>"
for {set x 0} {$x < [expr [llength $probab_classifier]-1]} {incr x} {
    set val [lindex $probab_classifier [expr $x+1]]
    append risk_chart_header "<td width=20 align=center>$val</td>\n"
}
set risk_chart_header "<tr>$risk_chart_header</tr>\n"

set risk_chart_html "<table id=risk_chart border=1 align=right style='border-collapse:separate'>\n"
for {set y [expr [llength $impact_classifier]-2]} {$y >= 0} {incr y -1} {
    set risk_chart_line ""
    set val [lindex $impact_classifier [expr $y+1]]
    append risk_chart_line "<tr>\n<td align=right width=$cell_width>$val</td>\n"
    for {set x 0} {$x < [expr [llength $probab_classifier]-1]} {incr x} {
	set key "$y-$x"
	set v ""
	if {[info exists chart_hash($key)]} { set v $chart_hash($key) }
	set v_ids {}
	if {[info exists chart_ids_hash($key)]} { set v_ids $chart_ids_hash($key) }
	set color [im_risk_chart_bg_color -x $x -y $y -max [llength $probab_classifier]]
	set v_url [export_vars -base "/intranet-riskmanagement/index" {return_url {risk_project_id $project_id} {risk_ids $v_ids}}]
	append risk_chart_line "<td align=center bgcolor=$color width=$cell_width><a href='$v_url'>$v</a></td>\n"
    }
    append risk_chart_line "</tr>\n"
    append risk_chart_html $risk_chart_line
}
append risk_chart_html $risk_chart_header
append risk_chart_html "</table>\n"

# Show a resonable message if no budget was specified
if {"" == $project_budget || 0 == $project_budget} {
    set risk_chart_html "
	<b>[lang::message::lookup "" intranet-riskmanagement.No_project_budget_specified "No project budget specified"]</b>:
	[lang::message::lookup "" intranet-riskmanagement.Without_budget_no_chart "Without the budget we can't calculate the risk chart."]<br>
	[lang::message::lookup "" intranet-riskmanagement.Please_set_the_project_budget "Please edit the project and set a budget"]
    "
}

if {"" == $project_id} {
    set risk_chart_html ""
}



# ---------------------------------------------------------
# Format risk related reports
# ---------------------------------------------------------


# Add the <ul>-List of associated menus
set bind_vars [list project_id $project_id]
set menu_html [im_menu_li -bind_vars $bind_vars "reporting-project-risks"]

set import_exists_p [llength [info commands im_csv_import_object_fields]]
set import_html "<li><a href=[export_vars -base "/intranet-csv-import/index" {{object_type im_risk}}]>[lang::message::lookup "" intranet-timesheet2.Import_Risk_CSV "Import Risk CSV"]</a>"
if {!$import_exists_p} { set import_html "" }


# ---------------------------------------------------------
# Table footer
# with action box
# ---------------------------------------------------------

set new_risk_url [export_vars -base "/intranet-riskmanagement/new" {return_url {risk_project_id $project_id}}]
set new_risk_msg [lang::message::lookup "" intranet-rismanagement.New_Risk "New Risk"]
set delete_risk_msg [lang::message::lookup "" intranet-rismanagement.Delete_Risks "Delete Risks"]
set table_footer_html "
<tr>
<td colspan=99>
<select name=action>
<option value=delete>$delete_risk_msg<option>
</select>
<input type=submit>
<ul>
<li><a href='$new_risk_url'>$new_risk_msg</a>
$menu_html
$import_html
</ul>
</td>
</tr>
"

