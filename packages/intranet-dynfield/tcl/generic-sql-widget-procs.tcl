ad_library {

    Additional Widgets for use with the intranet-dynfield
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-25
    @cvs-id $Id$
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


    # ---------------------------------------------------------------
    # Initialize substitution variables from SQL statement
    #

    # "%varname%" expressions
    set var_list [regexp -all -inline {%[a-zA-Z0-9_]+%} $sql_statement]
    set var_list [lsort -unique $var_list]
    foreach var $var_list {
	if {[regexp {%([a-zA-Z0-9_]+)%} $var match var_name]} {
	    set substitution_hash($var_name) ""
	}
    }

    # ":varname" expressions
    set var_list [regexp -all -inline {\:[a-zA-Z0-9_]+} $sql_statement]
    set var_list [lsort -unique $var_list]
    foreach var $var_list {
	if {[regexp {\:([a-zA-Z0-9_]+)} $var match var_name]} {
	    set substitution_hash($var_name) ""
	}
    }

    # ---------------------------------------------------------------
    # Perform variable substitution with URL variables
    #
    set substitution_hash(user_id) [ad_get_user_id]
    set form_vars [ns_conn form]
    foreach form_var [ad_ns_set_keys $form_vars] {
	set form_val [ns_set get $form_vars $form_var]
	set substitution_hash($form_var) $form_val
    }

    set substitution_list [array get substitution_hash]
 
    # ---------------------------------------------------------------
    # Evaluate the SQL
    #
    set key_value_list [list]
    if {[catch {

	# evaluate TCL commands embedded into the SQL, such as [ad_get_user_id] etc.
	set sql_statement [lang::message::format $sql_statement $substitution_list]
	eval "set sql_statement \"$sql_statement\""

	# Use db_exec in order to handle $bind vars.
	# apart from that, these following block is equivalent 
	# with db_list_of_lists...
	#
	set bind [array get substitution_hash]
	set col_names ""
	set key_value_list [list]
	db_with_handle db {
	    set selection [db_exec select $db query $sql_statement 1]
	    while { [db_getrow $db $selection] } {
		set col_names [ad_ns_set_keys $selection]
		set this_result [list]
		set row_vals [list]
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    set var [lindex $col_names $i]
		    set val [ns_set value $selection $i]
		    lappend row_vals $val
		}
		lappend key_value_list $row_vals
	    }
	}
    
    } errmsg]} {
	return "Generic SQL Widget: Error executing SQL statment <pre>'$sql_statement'</pre>: <br>
	<pre>$errmsg</pre>"
    }


    array set attributes $tag_attributes

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
