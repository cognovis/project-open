
# Variables from page:
# project_id

if {![info exists view_name] || "" == $view_name} { set view_name "im_risk_list_short" }
set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

set return_url [im_url_with_query]

# ---------------------------------------------------------
# Define constants for classifying risks
# ---------------------------------------------------------

set project_budget [db_string budget "
	select	project_budget
	from	im_projects
	where	project_id = :project_id
" -default ""]

# Classifiers for impact and probability.
# Each classified starts with 0 and ends at "ininite"
set impact_classifier [list 0 [expr $project_budget * 10.0 / 100.0] [expr $project_budget * 30.0 / 100.0] [expr 1E20] ]
set probability_classifier [list 0 [expr 10.0] [expr  30.0] 100.0]

ad_proc im_risk_classify {
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
	if {$value >= $low && $value <= $high} { set result $i}
    }
    return $result
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
# ---------------------------------------------------------

set risk_sql "
	select	r.*,
		im_category_from_id(r.risk_type_id) as risk_type,
		im_category_from_id(r.risk_status_id) as risk_status
	from	im_risks r
	where	risk_project_id = :project_id
	order by risk_probability_percent * risk_impact DESC;
"

set ctr 0
set table_body_html ""
set risk_widget_html ""
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
    set impact_class [im_risk_classify -value $risk_impact -classifier $impact_classifier]
    set probability_class [im_risk_classify -value $risk_probability_percent -classifier $probability_classifier]
    if {"" == $impact_class || "" == $probability_class} {
	ad_return_complaint 1 "impact=$impact_class, prob=$probability_class"
    }
    set key "$impact_class-$probability_class"
    set v 0
    incr ctr
}


# Show a resonable message if no budget was specified
if {"" == $project_budget || 0 == $project_budget} {
    set risk_widget_html "
	<b>[lang::message::lookup "" intranet-riskmanagement.No_project_budget_specified "No project budget specified"]</b>:
	[lang::message::lookup "" intranet-riskmanagement.Without_budget_no_widget "Without the budget we can't calculate the risk chart."]<br>
	[lang::message::lookup "" intranet-riskmanagement.Please_set_the_project_budget "Please edit the project and set a budget"]
    "
}
