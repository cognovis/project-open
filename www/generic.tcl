
# Called as a component

if {![info exists component_name]} { set component_name "Undefined Component" }
if {![info exists cube_name]} { set  cube_name "finance" }
if {![info exists start_date]} { set start_date "" }
if {![info exists end_date]} { set end_date "" }
if {![info exists cost_type_id]} { set cost_type_id "3700" }
if {![info exists top_vars]} { set top_vars "year" }
if {![info exists left_vars]} { set left_vars "customer_name" }
if {![info exists return_url]} { set return_url ""}


set sigma "&Sigma;"

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
	-start_color "0080FF" \
	-end_color "80FF80" \
	-radius 70 \
	-outer_distance 10 \
]

set show_details_msg [lang::message::lookup "" intranet-reporting-dashboard.Show_Details "Show Details"]
set cube_link "<a href=[export_vars -base "/intranet-reporting-cubes/${cube_name}-cube" {top_vars left_vars start_date end_date cost_type_id}]>$show_details_msg</a>\n"

