ad_library {

    Additional OpenACS Widgets for use with the DynField
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-25
    @cvs-id $Id: hidden-widget-procs.tcl,v 1.4 2006/04/07 23:07:39 cvs Exp $
}


ad_proc -public template::widget::dynfield_hidden { element_reference tag_attributes } {
    Hidden Widget

    @param expresion to get widget value.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#    ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"


    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Dynfield Hidden Widget: Error: Didn't find 'custom' parameter.<br>Please use a Parameter such as: <tt>{custom {sql {select sysdate from dual}}} </tt>"
    }

    set type [lindex $params 0]
    switch $type {
       "sql" {
    	   set sql_statement [lindex $params 1]
    	   set val [db_string sql_statement $sql_statement -default ""]
    	   } 
       "eval" {
       	   set string_to_eval [lindex $params 1]
       	   set val [eval $string_to_eval]
       	}
       default {
	return "Dynfield Hidden Widget: Error: Didn't find type '$type' option parameter"
	}
    }

    array set attributes $tag_attributes
    set attributes(multiple) {}

    
    set ret_html "<input type=hidden name=$element(name) value=\"$val\">\n"    
    
    return $ret_html
}
