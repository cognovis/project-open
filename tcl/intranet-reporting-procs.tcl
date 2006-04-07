# /packages/intranet-reporting/tcl/intranet-reporting-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Reporting Component Library
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------
# Package Procs
# -------------------------------------------------------

ad_proc -public im_package_reporting_id {} {
    Returns the package id of the intranet-reporting module
} {
    return [util_memoize "im_package_reporting_id_helper"]
}

ad_proc -private im_package_reporting_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-reporting'
    } -default 0]
}


# -------------------------------------------------------
# Reporting Procs
# -------------------------------------------------------


ad_proc im_report_render_cell {
    -cell
    -cell_class
} {
    Renders one cell via ns_write directly
    into a report HTTP session
} {
    set td_fields ""

    # Remove leading spaces
    regexp {^[ ]*(.*)} $cell match cell

    while {[regexp {^\#([^=]*)\=([^ ]*)} $cell match key value rest]} {
	set match_len [string length $match]
	set rest [string range $cell $match_len end]
	regexp {^[ ]*(.*)} $rest match rest

	set key [string tolower $key]
	set cell $rest

	if {[string equal $key "class"]} {
	    set cell_class $value
	} else {
	    append td_fields "$key=$value "
	}
    }
    
    if {"" != $cell_class} { append td_fields "class=$cell_class " }
    ns_write "<td $td_fields>$cell</td>\n"
}

ad_proc im_report_render_row {
    -row
    -row_class
    -cell_class
    {-upvar_level 0}
} {
    Renders one line of a report via ns_write directly
    into a report HTTP session
} {
    ns_write "<tr class=$row_class>\n"
    foreach field $row {
	set value ""
	if {"" != $field} {
	    set cmd "set value \"$field\""
	    set value [uplevel $upvar_level $cmd]
	}
	im_report_render_cell -cell $value -cell_class $cell_class
    }
    ns_write "</tr>\n"
}


ad_proc im_report_render_header {
    -group_def
    -last_value_array_list
    {-level_of_detail 999}
    {-row_class ""}
    {-cell_class ""}
} {
    Renders a single row in a project-open report. 
    The procedure takes a report definition, an array of the
    "last_values" (from the last row) and the current variables
    via upvar and writes a report line to the page via ns_write.
    Returns an array of the new values for the current row.
} {
    set group_level 1
    ns_log Notice "render_header:"
    ns_log Notice "render_header: last_value_array_list=$last_value_array_list"
    array set last_value_array $last_value_array_list

    # Walk through the levels of the report definition
    while {[llength $group_def] > 0} {

	# -------------------------------------------------------
	# Extract the definition of the current level from the definition
	array set group_array $group_def
	set group_var $group_array(group_by)
	set header $group_array(header)
	set content $group_array(content)
	ns_log Notice "render_header: level=$group_level, group_var=$group_var"

	# -------------------------------------------------------
	# Determine last and new value for the current group group_level
	set last_value ""
	set new_value ""
	if {$group_var != ""} {
	    if {[info exists last_value_array($group_level)]} {
		set last_value $last_value_array($group_level)
	    }
	    upvar $group_var $group_var
	    
	    if {![info exists $group_var]} {
		ad_return_complaint 1 "Header: Level $group_level: Group var '$group_var' doesn't exist" 
	    }
	    set cmd "set new_value \"\$$group_var\""
	    eval $cmd
	    ns_log Notice "render_header: level=$group_level, last_value='$last_value', new_value='$new_value'"
	}

	# -------------------------------------------------------
	# Write out the header if last_value != new_value

	if { ($content == "" || $new_value != $last_value) && ($group_level <= $level_of_detail) && [llength $header] > 0} {
	    ns_write "<tr>\n"
	    foreach field $header {
		set value ""
		if {"" != $field} {
		    set cmd "set value \"$field\""
		    set value [uplevel 1 $cmd]
		}
		im_report_render_cell -cell $value -cell_class $cell_class
	    }
	    ns_write "</tr>\n"
	}

	# -------------------------------------------------------
	# Set the "old_var" to the currently new var
	set last_value_array($group_level) $new_value

	# -------------------------------------------------------
	# Prepare the next iteration of the while loop:
	# continue with the "row" part of the current level
	set group_def {}
	if {[info exists group_array(content)]} {
	    set group_def $group_array(content)
	}
	incr group_level

    }
    ns_log Notice "render_header: after group_by headers"

    return [array get last_value_array]
}




ad_proc im_report_render_footer {
    -group_def
    -last_value_array_list
    {-row_class ""}
    {-cell_class ""}
    {-level_of_detail 999}
} {
    Renders the footer stack of a single row in a project-open report. 
    The procedure acts similar to im_report_render_header,
    but returns a list of results instead of writing the results
    to the web page immediately.
    This is done, because the decision what footer lines to display
    can only be taken when the next row is displayed.
    Returns a list of report lines, each together with the group_var.
    A group_var with a value different from the current one is the
    trigger to display the footer line.
} {
    ns_log Notice "render_footer:"
    array set last_value_array $last_value_array_list

    # Split group_def and assign to an array for reverse access
    set group_level 1
    while {[llength $group_def] > 0} {
	set group_def_array($group_level) $group_def
	ns_log Notice "render_footer: group_def_array($group_level) = ..."
	array set group_array $group_def
        set group_def {}
        if {[info exists group_array(content)]} {
            set group_def $group_array(content)
        }
        incr group_level
    }
    set group_level [expr $group_level - 1]

    while {$group_level > 0} {
	ns_log Notice "render_footer: level=$group_level"

	# -------------------------------------------------------
	# Extract the definition of the current level from the definition
	array set group_array $group_def_array($group_level)
	set group_var $group_array(group_by)
	set footer $group_array(footer)
	set content $group_array(content)

        # -------------------------------------------------------
        # Determine the new value for the current group_level
        set new_value ""
        if {$group_var != ""} {
            upvar $group_var $group_var
            if {![info exists $group_var]} {
                ad_return_complaint 1 "Header: Level $group_level: Group var '$group_var' doesn't exist"
            }
            set cmd "set new_value \"\$$group_var\""
            eval $cmd
            ns_log Notice "render_header: level=$group_level, new_value='$new_value'"
        }

	# -------------------------------------------------------
	# Write out the footer to an array
	set footer_line [list]
	foreach field $footer {
	    set value ""
	    if {"" != $field} {
		set cmd "set value \"$field\""
		set value [uplevel 1 $cmd]
	    }
	    lappend footer_line $value
	}
	set footer_record [list \
	    line $footer_line \
	    new_value $new_value
	]
	# Store the result for display later
	set footer_array($group_level) $footer_record

	set group_level [expr $group_level - 1]
    }
    ns_log Notice "render_footer: after group_by footers"

    return [array get footer_array]
}




ad_proc im_report_display_footer {
    -group_def
    -footer_array_list
    -last_value_array_list
    {-display_all_footers_p 0}
    {-level_of_detail 999}
    {-cell_class ""}
    {-row_class ""}
} {
    Display the footer stack of a single row in a project-open report. 
} {
    ns_log Notice "display_footer:"
    array set last_value_array $last_value_array_list
    array set footer_array $footer_array_list

    # -------------------------------------------------------
    # Abort if there are no footer values, because this
    # is probably the first time that this routine is executed
    if {[llength $footer_array_list] == 0} {
	return
    }

    set group_def_org $group_def

    # -------------------------------------------------------
    # Determine the "return_group_level" to which we have to go _back_.
    # This level determines the number of footers that we need to write out.
    #
    set return_group_level 1
    while {[llength $group_def] > 0} {

	# -------------------------------------------------------
	# Extract the definition of the current level from the definition
	array set group_array $group_def
	set group_var $group_array(group_by)
	set header $group_array(header)
	set content $group_array(content)
	ns_log Notice "display_footer: level=$return_group_level, group_var=$group_var"

	# -------------------------------------------------------
	# 
	set footer_record_list $footer_array($return_group_level)
	array set footer_record $footer_record_list
	set new_record_value $footer_record(new_value)

	# -------------------------------------------------------
	# Determine new value for the current group return_group_level
	set new_value ""
	if {$group_var != ""} {
	    upvar $group_var $group_var
	    set cmd "set new_value \"\$$group_var\""
	    eval $cmd
	}

	# -------------------------------------------------------
	# Check if new_value != new_record_value.
	# In this case we have found the first level in which the
	# results differ. This is the level where we have to return.
	ns_log Notice "display_footer: level=$return_group_level, group_var=$group_var, new_record_value=$new_record_value, new_value=$new_value"
	if {![string equal $new_value $new_record_value]} {
	    # leave the while loop
	    break
	}

	# -------------------------------------------------------
	# Prepare the next iteration of the while loop:
	# continue with the "row" part of the current level
	set group_def {}
	if {[info exists group_array(content)]} {
	    set group_def $group_array(content)
	}
	incr return_group_level

    }

    # Restore the group_def destroyed by the previous while loop
    set group_def $group_def_org


    # -------------------------------------------------------
    # Calculate the maximum level in the report definition
    set max_group_level 1
    while {[llength $group_def] > 0} {
	set group_def_array($max_group_level) $group_def
	ns_log Notice "display_footer: group_def_array($max_group_level) = ..."
	array set group_array $group_def
        set group_def {}
        if {[info exists group_array(content)]} {
            set group_def $group_array(content)
        }
        incr max_group_level
    }
    set max_group_level [expr $max_group_level - 2]


    if {$display_all_footers_p} { set return_group_level 1 }
    if {$max_group_level > $level_of_detail} { set max_group_level $level_of_detail }

    # -------------------------------------------------------
    # Now let's display all footers between max_group_level and
    # return_group_level.
    #
    ns_log Notice "display_footer: max_group_level=$max_group_level, return_group_level=$return_group_level"
    for {set group_level $max_group_level} { $group_level >= $return_group_level} { set group_level [expr $group_level-1]} {

	# -------------------------------------------------------
	# Extract the footer_line
	#
	set footer_record_list $footer_array($group_level)
	array set footer_record $footer_record_list
	set new_record_value $footer_record(new_value)
	set footer_line $footer_record(line)

	# -------------------------------------------------------
	# Write out the header if last_value != new_value

	ns_log Notice "display_footer: writing footer for group_level=$group_level"
	ns_write "<tr>\n"
	foreach field $footer_line {
	    im_report_render_cell -cell $field -cell_class $cell_class
	}
	ns_write "</tr>\n"

    }
}





ad_proc im_report_update_counters {
    -counters
} {
    Takes a definition of the report counters
    and update the counter values according to
    the variables in the parent frame
} {
    upvar counter_sum counter_sum
    upvar counter_count counter_count
    upvar counter_reset counter_reset

    foreach counter_list $counters {
	array set counter $counter_list
	set pretty_name $counter(pretty_name)
	set reset $counter(reset)
	set var $counter(var)
	set expr $counter(expr)

	# Reset the counter if necessary
	set last_reset ""
	set reset_performed 0
	if {[info exists counter_reset($var)]} { 
	    set last_reset $counter_reset($var) 
	}

	set cmd "set reset_val \[expr $reset\]"
	set reset_val [uplevel 1 $cmd]

	set cmd "set expr_val \[expr $expr\]"
	set expr_val [uplevel 1 $cmd]

	if {$last_reset != $reset_val} {
	    set counter_sum($var) 0
	    set counter_count($var) 0
	    set counter_reset($var) $reset_val
	    set reset_performed 1
	}

	# Update the counter
	set last_sum 0
	if {[info exists counter_sum($var)]} { 
	    set last_sum $counter_sum($var) 
	}

	set last_count $counter_count($var)
	set last_sum [expr $last_sum + $expr_val]


	incr last_count
	set counter_sum($var) $last_sum
	set counter_count($var) $last_count

	# Store the counter result in a local variable,
	# so that the row expressions can access it
	upvar $var $var
	set $var $last_sum
    }
}

ad_proc im_report_skip_if_zero {
    amount
    string
} {
    Returns an empty string if "amount" is zero.
    This is used to suppress "0 EUR" sums if the sum
    was zero...
} {
    if {0 == $amount} { return "" }
    return $string
}