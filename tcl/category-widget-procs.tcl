ad_library {

    Additional OpenACS Widgets for use with the FlexBase
    extensible architecture

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-06
    @cvs-id $Id$

}


ad_proc -public template::widget::category_tree { element_reference tag_attributes } {
    Category Tree Widget

    @param category_tree_id The ID of the category tree (see categories
           package) for valid choice options.

    The widget takes a tree from the categories package and displays all
    of its leaves in an indented drop-down box. For details on creating
    and modifying FlexBase widgets please see the FlexBase documentation.
} {
    upvar $element_reference element

#   Show all availabe variables in the variable frame
#   ad_return_complaint 1 "<pre>\n'$element(custom)'\n[array names element]\n</pre>"

    if { [info exists element(custom)] } {
    	set params $element(custom)
    } else {
	return "Category Widget: Error: Didn't find 'custom' parameter.<br>
        Please use a Parameter such as: <tt>{custom {category_tree_id 630}} </tt>"
    }

    set tree_pos [lsearch $params category_tree_id]
    if { $tree_pos >= 0 } {
    	set tree_id [lindex $params [expr $tree_pos + 1]]
    } else {
	return "Category Widget: Error: Didn't find 'category_tree_id' parameter"
    }

    array set attributes $tag_attributes
    #set attributes(multiple) {}
    set category_html ""
    set default_value_list $element(values)  	
    
    if { "edit" != $element(mode)} {
    	set category_list [category_tree::get_tree $tree_id] 
    	set i 1
    	set n_category [llength $category_list]
    	foreach category  $category_list {
		set cat_id [lindex $category 0]
		set cat_name [lindex $category 1]
		set cat_depr [lindex $category 2]
		set cat_level [lindex $category 3]

	    if {[lsearch -exact $default_value_list $cat_id] != -1} {
	    	
		append category_html "$cat_name"
		
		if {$i < $n_category} {
			append category_html ","
	    	}
		append category_html " <input type=\"hidden\" name=\"$element(name)\" id=\"$element(name)\"value=\"$cat_id\">"
	    }
	    incr i
    	}

    } else {
    	    	
    	#ns_log notice "category_widget ---------------> $element(html)"
    	set category_html "<select name=\"$element(name)\" id=\"$element(name)\" "
    	if {[exists_and_not_null element(multiple_p)] && $element(multiple_p)} {
    		set multiple_p 1
    	} else {
    		set multiple_p 0
    	}
    	
    	if {$multiple_p} {
    		append category_html " multiple=\"multiple\" "
    	}
   	foreach name [array names attributes] {
	      if { [string equal $attributes($name) {}] } {
	        append category_html " $name"
	      } else {
	        append category_html " $name=\"$attributes($name)\""
	      }
   	}
   	set i 0
   	while {$i < [llength $element(html)]} {
   		append category_html " [lindex $element(html) $i]=\"[lindex $element(html) [expr $i + 1]]\""
   		incr i 2
   	}

    	append category_html ">\n "
    	if {[exists_and_not_null element(optional)] && $element(optional) && !$multiple_p} {
    		append category_html "<option value=\"\"> [_ flexbase.no_value]</option>"
    	}
    	foreach category [category_tree::get_tree $tree_id] {
		set cat_id [lindex $category 0]
		set cat_name [lindex $category 1]
		set cat_depr [lindex $category 2]
		set cat_level [lindex $category 3]

		set indent ""
		if {$cat_level>1} {
			set indent [category::repeat_string "&nbsp;" [expr 2 * $cat_level]]
    		}
    		# notice "\n \n \n ******************* category_widget indent $indent"
    		if {[lsearch -exact $default_value_list $cat_id] == -1} {
    	   		append category_html "<option value=\"$cat_id\"> $indent $cat_name&nbsp;&nbsp;</option>"
    		} else {
    	    		append category_html "<option value=\"$cat_id\" selected=\"selected\"> $indent $cat_name&nbsp;&nbsp;</option>"
        	}
    	}
    	append category_html "\n</select>\n"
    }

    return $category_html
}
