ad_library {

    Additional Project/Open Widget for use with Intrnaet-DynField

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-06-06
    @cvs-id $Id$

}


ad_proc -public template::widget::im_category_tree { element_reference tag_attributes } {
    Category Tree Widget

    @param category_type The name of the category type (see categories
           package) for valid choice options.

    The widget takes a tree from the categories package and displays all
    of its leaves in an indented drop-down box. For details on creating
    and modifying widgets please see the documentation.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"

    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Intranet Category Widget: Error: Didn't find 'custom' parameter.<br>
        Please use a Parameter such as: <tt>{custom {category_type \"Intranet Company Type\"}} </tt>"
    }

    set category_type_pos [lsearch $params category_type]
    if { $category_type_pos >= 0 } {
    	set category_type [lindex $params [expr $category_type_pos + 1]]
    } else {
	return "Intranet Category Widget: Error: Didn't find 'category_type' parameter"
    }

    array set attributes $tag_attributes
    set category_html ""
    set default_value_list $element(values)  	
    
    if { "edit" != $element(mode)} {

	append category_html [im_category_select $category_type $element(name)]

    } else {
    	    	
	append category_html [im_category_select $category_type $element(name)]

    }

    return $category_html
}
