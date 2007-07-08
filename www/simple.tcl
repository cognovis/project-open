ad_page_contract {
} {
    
}

set start_date [db_string start "select to_date(now()::date-10000, 'YYYY-MM-01')"]
set end_date [db_string start "select to_date(now()::date+60, 'YYYY-MM-01')"]
set sigma "&Sigma;"

set cube_array [im_reporting_cubes_cube \
    -cube_name "finance" \
    -start_date $start_date \
    -end_date $end_date \
    -left_vars "customer_name" \
    -top_vars "" \
    -cost_type_id {3700} \
    -customer_type_id 0 \
    -customer_id 0 \
]

array set cube $cube_array

# Extract the variables from cube
set left_scale $cube(left_scale)
set top_scale $cube(top_scale)
array set hash $cube(hash_array)

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
]

