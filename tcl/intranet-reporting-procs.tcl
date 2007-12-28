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
# Constants
# -------------------------------------------------------

ad_proc -public im_report_status_active {} { return 15000 }
ad_proc -public im_report_status_deleted {} { return 15002 }

ad_proc -public im_report_type_simple_sql {} { return 15100 }
ad_proc -public im_report_type_indicator {} { return 15110 }


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
# Report specific number formatting
#
# Needed for localized versions of Excel that take either
# "." or "," as decimal separator
# -------------------------------------------------------

ad_proc im_report_format_number {
    amount
    {output_format "csv"}
    {locale ""}
    {rounding_precision 2}
} {
    Write out the number in a suitably formatted way for the 
    output medium.
} {
    if {"" == $locale} { set locale [lang::user::locale] }
    set amount_zeros [im_numeric_add_trailing_zeros [expr $amount+0] $rounding_precision]
    set amount_pretty [lc_numeric $amount_zeros "" $locale]
    return $amount_pretty
}


# -------------------------------------------------------
# Reporting Procs
# -------------------------------------------------------

ad_proc im_report_quote_cell {
    {-encoding ""}
    {-output_format "html"}
    cell
} {
    Take care of output specific characters: 
    <li> Quote HTML characters for HTML
    <li> Quote double quotes for CSV
} {
    switch $output_format {
	html { 
	    if {"" != $encoding} {
		set cell [encoding convertto $encoding $cell]
	    }
	    return $cell 
	}
	default { 

	    # Remove any <..> tags from the cell that are used
	    # for HTML formatting
	    regsub -all {\<[^\>]*\>} $cell "" cell

	    # Remove "&nbsp;" spaces
	    regsub -all {\&nbsp\;} $cell " " cell

	    # Quote all double quotes by doubling them
	    regsub -all {\"} $cell "\"\"" cell

	    # Convert to target encoding scheme 
	    if {"" != $encoding} {
		set cell [encoding convertto $encoding $cell]
	    }

	    # Remove leading and trailing spaces
	    set cell [string trim $cell]

	    return $cell
	}
    }
}

ad_proc im_report_render_cell {
    -cell
    -cell_class
    {-encoding ""}
    {-output_format "html"}
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

    # Check for cell values starting with "-". This gives a Syntax Error at runtime!!
    if {"-" == [string range $cell 0 0]} { set cell " $cell" }
    
    if {"" != $cell_class} { append td_fields "class=$cell_class " }
    set quoted_cell [im_report_quote_cell -encoding $encoding -output_format $output_format $cell]

    switch $output_format {
	html { ns_write "<td $td_fields>$quoted_cell</td>\n" }
	csv { ns_write "\"$quoted_cell\";" }
   }
}

ad_proc im_report_render_row {
    -row
    -row_class
    -cell_class
    {-encoding ""}
    {-output_format "html"}
    {-upvar_level 0}
} {
    Renders one line of a report via ns_write directly
    into a report HTTP session
} {
    switch $output_format {
        html { ns_write "<tr class=$row_class>\n" }
        csv { }
    }

    foreach field $row {
	set value ""
	if {"" != $field} {
	    set cmd "set value \"$field\""
	    set value [uplevel $upvar_level $cmd]
	}
	im_report_render_cell -encoding $encoding -output_format $output_format -cell $value -cell_class $cell_class
    }

    switch $output_format {
        html { ns_write "</tr>\n" }
        csv { ns_write "\n" }
    }
}


ad_proc im_report_render_header {
    -group_def
    -last_value_array_list
    {-encoding ""}
    {-output_format "html"}
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
	    switch $output_format {
		html { ns_write "<tr>\n" }
		csv { }
	    }

	    foreach field $header {
		set value ""
		if {"" != $field} {
		    set cmd "set value \"$field\""
		    set value [uplevel 1 $cmd]
		}
		im_report_render_cell -encoding $encoding -output_format $output_format -cell $value -cell_class $cell_class
	    }
	    
	    switch $output_format {
		html { ns_write "</tr>\n" }
		csv { ns_write "\n" }
	    }
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
    {-encoding ""}
    {-output_format "html"}
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
            ns_log Notice "render_footer: level=$group_level, new_value='$new_value'"
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
    {-encoding ""}
    {-output_format "html"}
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

	switch $output_format {
	    html { ns_write "<tr>\n" }
	    csv {  }
	}

	foreach field $footer_line {
	    im_report_render_cell -encoding $encoding -output_format $output_format -cell $field -cell_class $cell_class
	}

	switch $output_format {
	    html { ns_write "</tr>\n" }
	    csv { ns_write "\n" }
	}

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



# -------------------------------------------------------
# Deal with CSV HTTP headers 
# -------------------------------------------------------


ad_proc im_report_output_format_select {
    name
    {locale ""}
    { output_format ""}
} {
    Returns a formatted select widget (radio buttons)
    to allow a user to select the output format
} {
    if {"" == $locale} { set locale [lang::user::locale] }

    set html_checked ""
    set excel_checked ""
    set csv_checked ""
    switch $output_format {
	html { set html_checked "checked" }
	excel { set excel_checked "checked" }
	csv { set csv_checked "checked" }
    }
    return "
	<nobr>
        <input name=$name type=radio value='html' $html_checked>HTML &nbsp;
 	<input name=$name type=radio value='csv' $csv_checked>CSV
        </nobr>
    "
}


ad_proc im_report_number_locale_select {
    name
    {locale ""}
} {
    Returns a formatted select widget (select)
    to allow a user to select the number locale of a report
} {
    if {"" == $locale} { set locale [lang::user::locale] }
    set locales [list de_DE en_US]

    set result "<select name=\"$name\">\n"
    foreach loc $locales {
	if {$locale == $loc} {
	    append result "<option value='$loc' selected>$loc</option>\n"
	} else {
	    append result "<option value='$loc'>$loc</option>\n"
	}
    }
    append result "</select>\n"
    return $result
}


ad_proc im_report_write_http_headers {
    -output_format
} {
    Writes a suitable HTTP header to the connection.
    We need this custom routine in order to deal with
    strange IE5/6 and MS-Excel behaviour that require
    Latin1 (iso-8859-1) or other encodings, depending 
    on the country specific version of Excel...
} {
    set content_type [im_report_content_type -output_format $output_format]
    set http_encoding [im_report_http_encoding -output_format $output_format]

    # ad_return_complaint 1 $http_encoding
    # set content_type "text/html"

    append content_type "; charset=$http_encoding"
    
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
    
    util_WriteWithExtraOutputHeaders $all_the_headers
    ns_startcontent -type $content_type
}


ad_proc im_report_content_type {
    -output_format
} {
    Returns the suitable MIME type for the given output_format
} {
    # return "text/html"

    switch $output_format {
        html { return "text/html" }
        csv { 
	    return [parameter::get_from_package_key \
			-package_key intranet-dw-light \
			-parameter CsvContentType \
			-default "application/csv" \
	    ]
	}
        default { return "text/plain" }
    }
}


ad_proc im_report_tcl_encoding {
    -output_format
} {
    Returns a suitable conversion for the 'encoding convertto' command.
    Please see 'encoding list' for a list of values and the TCL manuals
    for an introduction to character encoding.
    Please note that the values are similar to the HTTP encodings,
    but not identical.
} {
    switch $output_format {
        html { return "" }
        csv { 
	    return [parameter::get_from_package_key \
			-package_key intranet-dw-light \
			-parameter CsvTclCharacterEncoding \
			-default "iso8859-1" \
	    ]
	}
        default { return "" }
    }
}


ad_proc im_report_http_encoding {
    -output_format
} {
    Returns a suitable HTTP "Content-Type" value.
    Please note that the values are similar to the TCL encodings,
    but not identical.
} {
    switch $output_format {
        html { return "utf-8" }
        csv { 
	    return [parameter::get_from_package_key \
			-package_key intranet-dw-light \
			-parameter CsvHttpCharacterEncoding \
			-default "iso-8859-1" \
	    ]
	}
        default { return "utf-8" }
    }
}



# -------------------------------------------------------
# Pivot Table helper procs
# -------------------------------------------------------


ad_proc -public im_report_take_n_from_list { list n } {
    returns n elements from list
} {
    if {$n <= 0} { return [list $list] }

    set result [list]
    for {set i 0} {$i < [llength $list]} {incr i} {
        set elem [lindex $list $i]
        set left_rest [lrange $list 0 [expr $i-1]]
        set right_rest [lrange $list [expr $i+1] end]
        set rest [concat $left_rest $right_rest]
        set rest_perms [im_report_take_n_from_list $rest [expr $n-1]]

	foreach rest_perm $rest_perms {
	    lappend result $rest_perm
	}
    }
    return [lsort -unique $result]
}


ad_proc -public im_report_take_all_ordered_permutations { list } {
    returns all permutations of a list
} {
    set n [llength $list]

    set result [list]
    for {set i 0} {$i < [llength $list]} {incr i} {
	set result [concat $result [im_report_take_n_from_list $list $i]]
    }
    lappend result [list]
    return $result
}


