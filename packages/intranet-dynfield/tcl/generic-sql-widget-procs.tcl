ad_library {

    Additional Widgets for use with the intranet-dynfield
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-25
    @cvs-id $Id: generic-sql-widget-procs.tcl,v 1.11 2009/02/18 01:43:24 cvs Exp $
}


ad_proc -public template::widget::generic_sql { element_reference tag_attributes } {
    Generic SQL Select Widget

    @param select A SQL select statement returning a list of key-value
                  pairs that serve to define the values of a select
                  widget. A single select is suitable to display some
                  200 values. Please use a different widget if you
                  have to display more then these values.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"

    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Generic SQL Widget: Error: Didn't find 'custom' parameter.<br>Please use a Parameter such as: <tt>{custom {sql {select party_id, email from parties}}} </tt>"
    }

    set sql_pos [lsearch $params sql]
    if { $sql_pos >= 0 } {
    	set sql_statement [lindex $params [expr $sql_pos + 1]]
    } else {
	return "Generic SQL Widget: Error: Didn't find 'sql' parameter"
    }

    # The "memoize_max_age" adds an empty line
    set memoize_max_age [parameter::get_from_package_key -package_key intranet-dynfield -parameter GenericSQLWidgetMemoizeMaxAgeDefault -default 600]
    set memoize_max_age_pos [lsearch $params "memoize_max_age"]
    if { $memoize_max_age_pos >= 0 } {
        set memoize_max_age [lindex $params [expr $memoize_max_age_pos + 1]]
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
    if {[catch {
	# evaluate TCL commands embedded into the SQL, such as [ad_get_user_id] etc.
	eval "set sql_statement \"$sql_statement\""
	# Execute the SQL and cache the result
	set key_value_list [util_memoize [list db_list_of_lists sql_statement $sql_statement] $memoize_max_age]
    } errmsg]} {
	return "Generic SQL Widget: Error executing SQL statment <pre>'$sql_statement'</pre>: <br>
	<pre>$errmsg</pre>"
    }
    set sql_html ""
    set default_value ""
    if {[info exists element(value)]} { set default_value $element(value) }
    if { "edit" != $element(mode) } {
    	foreach sql $key_value_list {
		set key [lindex $sql 0]
		set value [lindex $sql 1]
		if {$key == $default_value} {
			append sql_html "$value
			<input type=\"hidden\" name=\"$element(name)\" id=\"$element(name)\" value=\"$key\">"
		}
    	}
    } else {
    	set sql_html "<select name=\"$element(name)\" id=\"$element(name)\" "
    		foreach name [array names attributes] {
			if { [string equal $attributes($name) {}] } {
				append sql_html " $name"
			} else {
				append sql_html " $name=\"$attributes($name)\""
			}
		}
		set i 0
		while {$i < [llength $element(html)]} {
			append sql_html " [lindex $element(html) $i]=\"[lindex $element(html) [expr $i + 1]]\""
			incr i 2
    		}
    	append sql_html " >\n"

    	if {$include_empty_p} {
		append sql_html "<option value=\"\">$include_empty_name</option>"
    	}

    	foreach sql $key_value_list {
		set key [lindex $sql 0]
		set value [lindex $sql 1]
		if {$key != $default_value} {
    	    		append sql_html "<option value=\"$key\">$value</option>"
        	} else {
        		append sql_html "<option value=\"$key\" selected=\"selected\">$value</option>"
        	}
    	}
    	append sql_html "\n</select>\n"
    }

    return $sql_html
}
