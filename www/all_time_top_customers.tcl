ad_page_contract {
} {
}

set cube_name "finance"
set start_date [db_string start "select to_date(now()::date-10000, 'YYYY-MM-01')"]
set end_date [db_string start "select to_date(now()::date+60, 'YYYY-MM-01')"]
set cost_type_id {3700}
set sigma "&Sigma;"

set top_vars "year"
set left_vars "customer_name"

set cube_array [im_reporting_cubes_cube \
    -cube_name $cube_name \
    -start_date $start_date \
    -end_date $end_date \
    -left_vars $left_vars \
    -top_vars $top_vars \
    -cost_type_id $cost_type_id \
]
array set cube $cube_array

# Extract the variables from cube
set left_scale $cube(left_scale)
set top_scale $cube(top_scale)
set hash_array $cube(hash_array)
array set hash $hash_array

# Extract the leftmost elements from the $left_scale
set pie_values [list]
foreach left_scale_line $left_scale {
    set pie_key [lindex $left_scale_line 0]
    if {$pie_key == $sigma} { continue }
    set val $hash($pie_key)
    lappend pie_values [list $pie_key $val]
}

set pie_chart [im_dashboard_pie_chart \
	-values $pie_values \
	-radius 70 \
	-outer_distance 10 \
]

set show_details_msg [lang::message::lookup "" intranet-reporting-dashboard.Show_Details "Show Details"]
set cube_link "<a href=[export_vars -base "/intranet-reporting-cubes/${cube_name}-cube" {top_vars left_vars start_date end_date cost_type_id}]>$show_details_msg</a>\n"

