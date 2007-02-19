# Category widgets for the ArsDigita Templating System

# Author: Timo Hentschel (timo@timohentschel.de)
#
# $Id: 

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

namespace eval template {}
namespace eval template::widget {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}

ad_proc -public template::widget::category { element_reference tag_attributes } {
    # author: Timo Hentschel (timo@timohentschel.de)

    upvar $element_reference element

    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    array set attributes $tag_attributes
    array set ms_attributes $tag_attributes
    set ms_attributes(multiple) {}
    
    set all_single_p [info exists attributes(single)]

    # Determine the size automatically for a multiselect
    if { ![info exists ms_attributes(size)] } {
	set ms_attributes(size) 5
    }

    # Get parameters for the category widget
    set object_id {}
    set package_id {}
    set tree_id {}
    set subtree_id {}
    set assign_single_p f
    set require_category_p f

    if { [exists_and_not_null element(value)] && [llength $element(value)] == 2 } {
        # Legacy method for passing parameters
        set object_id [lindex $element(value) 0]
        set package_id [lindex $element(value) 1]
    } else {
        if { [exists_and_not_null element(category_application_id)] } {
            set package_id $element(category_application_id)
        }
        if { [exists_and_not_null element(category_object_id)] } {
            set object_id $element(category_object_id)
        }
        if { [exists_and_not_null element(category_tree_id)] } {
            set tree_id $element(category_tree_id)
        }
        if { [exists_and_not_null element(category_subtree_id)] } {
            set subtree_id $element(category_subtree_id)
        }
        if { [exists_and_not_null element(category_assign_single_p)] } {
            set assign_single_p $element(category_assign_single_p)
        }
        if { [exists_and_not_null element(category_require_category_p)] } {
            set require_category_p $element(category_require_category_p)
        }
    }
    if { [empty_string_p $package_id] } {
	set package_id [ad_conn package_id]
    }

    if { ![empty_string_p $object_id] && ![info exists element(submit)] } {
        set mapped_categories [category::get_mapped_categories $object_id]
    } else {
	set mapped_categories [ns_querygetall $element(id)]
	# QUIRK: ns_querygetall returns a single-element list {{}} for no values
	if { [string equal $mapped_categories {{}}] } {
	    set mapped_categories [list]
	}
    }
    set output {}

    if { [empty_string_p $tree_id] } {
        set mapped_trees [category_tree::get_mapped_trees $package_id]
    } else {
        set mapped_trees [list [list $tree_id [category_tree::get_name $tree_id] $subtree_id $assign_single_p $require_category_p]]
    }

    foreach mapped_tree $mapped_trees {
	util_unlist $mapped_tree tree_id tree_name subtree_id assign_single_p require_category_p
	set tree_name [ad_quotehtml $tree_name]
	set one_tree [list]

	foreach category [category_tree::get_tree -subtree_id $subtree_id $tree_id] {
	    util_unlist $category category_id category_name deprecated_p level
	    set category_name [ad_quotehtml $category_name]
	    if { $level>1 } {
		set category_name "[string repeat "&nbsp;" [expr 2*$level -4]]..$category_name"
	    }
	    lappend one_tree [list $category_name $category_id]
	}

        if { [llength $mapped_trees] > 1 } {
            append output " $tree_name\: "
	}

	if {$assign_single_p == "t" || $all_single_p} {
	    # single-select widget
            if { $require_category_p == "f" } {
                set one_tree [concat [list [list "" ""]] $one_tree]
            }
	    append output [template::widget::menu $element(name) $one_tree $mapped_categories attributes $element(mode)]
	} else {
	    # multiselect widget (if user didn't override with single option)
	    append output [template::widget::menu $element(name) $one_tree $mapped_categories ms_attributes $element(mode)]
	}
    }

    return $output
}

ad_proc -public template::data::validate::category { value_ref message_ref } {
    # author: Timo Hentschel (timo@timohentschel.de)

    upvar 2 $message_ref message $value_ref values
    set invalid_values [list]

    foreach value $values {
	if {![regexp {^[+-]?\d+$} $value]} {
	    lappend invalid_values $value
	}
    }

    set result 1
    if {[llength $invalid_values] > 0} {
	set result 0
	if {[llength $invalid_values] == 1} {
	    set message "Invalid category [lindex $invalid_values 0]"
	} else {
	    set message "Invalid categories [join $invalid_values ", "]"
	}
    }
    
    return $result 
}

ad_proc -public template::data::transform::category { element_ref } {
    # author: Timo Hentschel (timo@timohentschel.de)

    upvar $element_ref element
    set values [ns_querygetall $element(id)]

    # QUIRK: ns_querygetall returns a single-element list {{}} for no values
    if { [string equal $values {{}}] } {
	set values [list]
    }

    # to mark submission of form for rendering element in case of invalid data
    # (to preselect with last selected values)
    set element(submit) 1

    # Get parameters for the category widget
    set package_id {}
    set tree_id {}
    set subtree_id {}
    set require_category_p f

    if { [exists_and_not_null element(value)] && [llength $element(value)] == 2 } {
        # Legacy method for passing parameters
        set package_id [lindex $element(value) 1]
    } else {
        if { [exists_and_not_null element(category_application_id)] } {
            set package_id $element(category_application_id)
        }
        if { [exists_and_not_null element(category_tree_id)] } {
            set tree_id $element(category_tree_id)
        }
        if { [exists_and_not_null element(category_subtree_id)] } {
            set subtree_id $element(category_subtree_id)
        }
        if { [exists_and_not_null element(category_require_category_p)] } {
            set require_category_p $element(category_require_category_p)
        }
    }
    if { [empty_string_p $package_id] } {
	set package_id [ad_conn package_id]
    }

    if { [empty_string_p $tree_id] } {
	set trees [list]
        foreach tree [category_tree::get_mapped_trees $package_id] {
	    util_unlist $tree tree_id tree_name subtree_id assign_single_p require_category_p
	    if {$require_category_p == "t" || ![info exists element(optional)]} {
		lappend trees [list $tree_id $subtree_id]
	    }
	}
    } else {
	if {$require_category_p == "t"} {
	    set trees [list [list $tree_id $subtree_id]]
	} else {
	    set trees [list]
	}
    }

    set trees_without_category [list]
    foreach tree $trees {
	util_unlist $tree tree_id subtree_id
	# get categories of every tree requiring a categorization
	foreach category [category_tree::get_tree -all -subtree_id $subtree_id $tree_id] {
	    set tree_categories([lindex $category 0]) 1
	}
	set found_p 0
	# check if at least one selected category is among tree categories
	foreach value $values {
	    if {[info exists tree_categories($value)]} {
		set found_p 1
	    }
	}
	if {!$found_p} {
	    # no categories of this tree selected, so add for error message
	    lappend trees_without_category [category_tree::get_name $tree_id]
	}
	array unset tree_categories
    }
    if {[llength $trees_without_category] > 0} {
	# some trees require category, but none selected
	template::element::set_error $element(form_id) $element(id) "Please select a category for [join $trees_without_category ", "]."
        return [list]
    }

    return $values
}
