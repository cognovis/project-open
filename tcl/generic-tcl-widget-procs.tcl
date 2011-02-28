ad_library {

    Additional Widgets for use with the intranet-dynfield
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @author Malte Sussdorff malte.sussdorff@cognovis.de
    @creation-date 2005-01-25
    @cvs-id $Id$
}


ad_proc -public template::widget::generic_tcl { element_reference tag_attributes } {
    Generic TCL Select Widget

    @param tcl A TCL code returning a list of key-value
                  pairs that serve to define the values of a select
                  widget. A single select is suitable to display some
                  200 values. Please use a different widget if you
                  have to display more then these values.
			
    @param switch_p Switch to value-key pairs
} {

    upvar $element_reference element
    
    #   Show all availabe variables in the variable frame
    #   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"
    
    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Generic TCL Widget: Error: Didn't find 'custom' parameter.<br>Please use a Parameter such as: <tt>{custom {tcl {select party_id, email from parties}}} </tt>"
    }

    set tcl_pos [lsearch $params tcl]
    if { $tcl_pos >= 0 } {
    	set tcl_code [lindex $params [expr $tcl_pos + 1]]
    } else {
	return "Generic tcl Widget: Error: Didn't find 'tcl' parameter"
    }
    
    set switch_pos [lsearch $params switch_p]
    if {$switch_pos >= 0} {
	set switch_p [lindex $params [expr $switch_pos +1]]
    } else {
	set switch_p 0
    }
    
    # Deal with global variables being pushed through
    set global_var_pos [lsearch $params global_var]
    if {$global_var_pos >= 0} {
	set global_var_name [lindex $params [expr $global_var_pos +1]]
	set $global_var_name [set ::$global_var_name]
    }
    
    
    # The "memoize_max_age" adds an empty line
    set memoize_max_age [parameter::get_from_package_key -package_key intranet-dynfield -parameter GenericSQLWidgetMemoizeMaxAgeDefault -default 600]
    set memoize_max_age_pos [lsearch $params "memoize_max_age"]
    if { $memoize_max_age_pos >= 0 } {
        set memoize_max_age [lindex $params [expr $memoize_max_age_pos + 1]]
    }
    
    
    set switch_pos [lsearch $params switch_p]
    if {$switch_pos >= 0} {
	set switch_p [lindex $params [expr $switch_pos +1]]
    } else {
	set switch_p 0
    }
    
    # Deal with global variables being pushed through
    set global_var_pos [lsearch $params global_var]
    if {$global_var_pos >= 0} {
	set global_var_name [lindex $params [expr $global_var_pos +1]]
	set $global_var_name [set ::$global_var_name]
	ds_comment "$global_var_name [set $global_var_name]"
    }
    
    set memoize_pos [lsearch $params memoize_p]
    if {$memoize_pos >= 0} {
	set memoize_p [lindex $params [expr $memoize_pos +1]]
    } else {
	set memoize_p 1
    }
    
    if {$memoize_p} {
	# The "memoize_max_age" adds an empty line
	set memoize_max_age [parameter::get_from_package_key -package_key intranet-dynfield -parameter GenericSQLWidgetMemoizeMaxAgeDefault -default 600]
	set memoize_max_age_pos [lsearch $params "memoize_max_age"]
	if { $memoize_max_age_pos >= 0 } {
	    set memoize_max_age [lindex $params [expr $memoize_max_age_pos + 1]]
	}
    } 

    # The "include_empty_p" adds an empty line
    set include_empty_p 1
    set include_empty_p_pos [lsearch $params include_empty_p]
    if { $include_empty_p_pos >= 0 } {
        set include_empty_p [lindex $params [expr $include_empty_p_pos + 1]]
    }

    # The "include_empty_name" pops up as first line
    set include_empty_name ""
    # [lang::message::lookup "" intranet-dynfield.no_value]
    set include_empty_name_pos [lsearch $params include_empty_name]
    if { $include_empty_name_pos >= 0 } {
        set include_empty_name [lindex $params [expr $include_empty_name_pos + 1]]
    }

    array set attributes $tag_attributes
    
    set key_value_list [list]
    if {[string first "$" $tcl_code] >= 0} {
	eval "set tcl_code \"$tcl_code\""
	ds_comment "$tcl_code"
    }
    
    if {$memoize_p} {
	if {[catch {
	    set key_value_list [util_memoize [list eval $tcl_code] $memoize_max_age]
	} errmsg]} {
	    return "Generic tcl Widget: Error executing tcl statment <pre>'$tcl_code'</pre>: <br>
                    <pre>$errmsg</pre>"
	}
    } else {
	if {[catch {
	    set key_value_list [eval $tcl_code]
	} errmsg]} {
	    return "Generic tcl Widget: Error executing tcl statment <pre>'$tcl_code'</pre>: <br>
                    <pre>$errmsg</pre>"
	}
    }
    set tcl_html ""
    set default_value ""
    if {[info exists element(value)]} { set default_value $element(value) }
    if { "edit" != $element(mode) } {
    	foreach tcl $key_value_list {
	    if {$switch_p} {
		set key [lindex $tcl 1]
		set value [lindex $tcl 0]
	    } else {
		set key [lindex $tcl 0]
		set value [lindex $tcl 1]	
	    }
	    if {$key != $default_value} {
		append tcl_html "<option value=\"$key\">$value</option>"
	    } else {
		append tcl_html "<option value=\"$key\" selected=\"selected\">$value</option>"
	    }
    	}
    	append tcl_html "\n</select>\n"
    
	if {$switch_p} {
	    set key [lindex $tcl 1]
	    set value [lindex $tcl 0]
	} else {
	    set key [lindex $tcl 0]
	    set value [lindex $tcl 1]	
	}
	if {$key == $default_value} {
	    append tcl_html "$value
			<input type=\"hidden\" name=\"$element(name)\" id=\"$element(name)\" value=\"$key\">"
	}
    } else {
	set tcl_html "<select name=\"$element(name)\" id=\"$element(name)\" "
	foreach name [array names attributes] {
	    if { [string equal $attributes($name) {}] } {
		append tcl_html " $name"
	    } else {
		append tcl_html " $name=\"$attributes($name)\""
	    }
	}
	set i 0
	while {$i < [llength $element(html)]} {
	    append tcl_html " [lindex $element(html) $i]=\"[lindex $element(html) [expr $i + 1]]\""
	    incr i 2
	}
    	append tcl_html " >\n"
	
    	if {$include_empty_p} {
	    append tcl_html "<option value=\"\">$include_empty_name</option>"
    	}
	
    	foreach tcl $key_value_list {
	    if {$switch_p} {
		set key [lindex $tcl 1]
		set value [lindex $tcl 0]
	    } else {
		set key [lindex $tcl 0]
		set value [lindex $tcl 1]	
	    }
	    if {$key != $default_value} {
		append tcl_html "<option value=\"$key\">$value</option>"
	    } else {
		append tcl_html "<option value=\"$key\" selected=\"selected\">$value</option>"
	    }
    	}
    	append tcl_html "\n</select>\n"
    }
    
    return $tcl_html
}
