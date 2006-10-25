# @arg row_count                The total number of rows.
# @arg offset                   The current row offset, i.e. the number of rows to skip. Must be an URL parameter.
# @arg interval_size            The number of rows per page. Must be an optional URL parameter
# @arg variable_set_to_export   An ns_set that should exclude the offset and interval_size variables. You may
#                               use ad_tcl_vars_to_ns_set to create this set.
# @arg pretty_plural            The plural form of whatever items we are paginating (i.e. in the Bug Tracker patches, or bugs)

set pagination_filter_list [list]
set interval_high $interval_size
set interval_low "1"

# Set all the variables to export to this template
set export_var_list [list]
for { set i 0 } { $i < [ns_set size $variable_set_to_export] } { incr i } {
    set var_name [ns_set key $variable_set_to_export $i]
    set $var_name [ns_set value $variable_set_to_export $i]
    lappend export_var_list $var_name
}

set pagination_filter_base_url "[ad_conn url]?[export_vars -url -exclude { offset } [concat $export_var_list interval_size]]"
set pagination_form_export_vars "[export_vars -form [concat $export_var_list offset]]"

while { $interval_low <= $row_count } {    

    if { $interval_high > $row_count } {
        set interval_high $row_count
    }

    set interval_label [ad_decode $interval_low $row_count "$interval_high" "$interval_low - $interval_high"]
    lappend pagination_filter_list [ad_decode [expr 1 + $offset] $interval_low "$interval_label" "<a href=\"$pagination_filter_base_url&offset=[expr $interval_low - 1]\">$interval_label</a>"]

    set interval_high [expr $interval_high + $interval_size]
    set interval_low [expr $interval_high - [expr $interval_size - 1]]
}

set pagination_filter [join $pagination_filter_list " | "]
