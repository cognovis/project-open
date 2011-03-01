ad_library {

    Additional Widgets for use with the intranet-dynfield
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-02-25
    @cvs-id $Id: calculated-sql-widget-procs.tcl,v 1.1 2008/02/15 20:53:36 cambridge Exp $
}


ad_proc -public template::widget::calculated_sql { element_reference tag_attributes } {
    Calculated Sql Widget

    @param select A SQL select statement returning a single value
                  or a list of values. These are simply displayed.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"

    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Calculated Sql Widget: Error: Didn't find 'custom' parameter.<br>Please use a Parameter such as: <tt>{custom {sql {select party_id, email from parties}}} </tt>"
    }

    set sql_pos [lsearch $params sql]
    if { $sql_pos >= 0 } {
    	set sql_statement [lindex $params [expr $sql_pos + 1]]
    } else {
	return "Calculated Sql Widget: Error: Didn't find 'sql' parameter"
    }

    array set attributes $tag_attributes

    set key_value_list [list]
    if {[catch {

	# Execute the SQL and cache the result
	set value [db_list sql $sql_statement]

    } errmsg]} {
	return "Calculated Sql Widget: Error executing SQL statment <pre>'$sql_statement'</pre>: <br>
	<pre>$errmsg</pre>"
    }
    set sql_html $value
    return $sql_html
}
