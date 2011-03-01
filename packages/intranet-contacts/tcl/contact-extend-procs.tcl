ad_library {

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-09-08
}

namespace eval contact::extend:: {}

ad_proc -public contact::extend::delete {
    -extend_id:required
} {
    Deletes one contact extend option
    @param extend_id The extend_id to delete
} {
    db_dml extend_delete { }
}

ad_proc -public contact::extend::new {
    -extend_id:required
    -var_name:required
    -pretty_name:required
    -subquery:required
    {-description ""}
    {-aggregated_p "f"}
} {
    Creates a new contact extend option
} {
    set var_name [string tolower $var_name]
    db_dml new_extend_option { }
}


ad_proc -public contact::extend::update {
    -extend_id:required
    -var_name:required
    -pretty_name:required
    -subquery:required
    {-description ""}
    {-aggregated_p "f"}
} {
    Updates one contact extend option
} {
    set var_name [string tolower $var_name]
    db_dml update_extend_option { }
}

ad_proc -public contact::extend::var_name_check {
    -var_name:required
} {
    Checks if the name is already present on the contact_extend_options table or not
} {
    set var_name [string tolower $var_name]
    return [db_string check_name { } -default "0"]
}

ad_proc -public contact::extend::get_options { 
    {-ignore_extends ""}
    -search_id:required
    -aggregated_p:required
} {
    Returns a list of the form { pretty_name extend_id } of all available extend options in
    contact_extend_options, if search_id is passed then ignore the extends in
    contact_search_extend_map

    @param ignore_extends A list of extend_id's to ignore on the result
    @param search_id The id of the search to get the mapped extend options
    @param aggregated_p Set it to t or f to get the extends that have aggregated_p set to t or f
} {
    set extra_query "where extend_id not in (select extend_id from contact_search_extend_map where search_id = $search_id)"
    if { ![empty_string_p $ignore_extends] } {
	set ignore_extends [join $ignore_extends ","]
	append extra_query "and extend_id not in ($ignore_extends)"
    }

    return [db_list_of_lists get_options " "]
}

ad_proc -public contact::extend::option_info { 
    -extend_id:required
} {
    Returns a list of the form { var_name pretty_name subquery description aggregated_p } of the extend_id
} {
    return [db_list_of_lists get_options { }]
}











namespace eval template::widget {}

ad_proc -public template::widget::select_with_optgroup { element_reference tag_attributes } {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes
    set options_list $element(options)
    set widget_name $element(name)
    set element_mode $element(mode)

    # edit...
    # Create an array for easier testing of selected values
    template::util::list_to_lookup $element(values) values

    if { ![string equal $element(mode) "edit"] } {
	# this is the same as the menu display.
        # we may want to customize it to use the optgroup
        # as some sort of heading for certain options
        set selected_list [list]

        foreach option $options_list {
	    
            set label [lindex $option 0]
            set value [lindex $option 1]
	    
            if { [info exists values($value)] } {
                lappend selected_list $label
                append output "<input type=\"hidden\" name=\"$widget_name\" value=\"[ad_quotehtml $value]\">"
            }
        }

        append output [join $selected_list ", "]
    } else {
	

	append output "<select name=\"$widget_name\" "
	foreach name [array names attributes] {
	    if { [string equal $attributes($name) {}] } {
		append output " $name=\"$name\""
	    } else {
		append output " $name=\"$attributes($name)\""
	    }
	}
	append output ">\n"


	set optgroup {}
	foreach option $options_list {
	    
	    set label [lindex $option 0]
	    set value [lindex $option 1]
	    set group [string trim [lindex $option 2]]


	    if { $group eq "" } {
		if { $optgroup ne "" } {
		    append output "</optgroup>\n"
		}
		set optgroup {}
	    } elseif { $group ne $optgroup } {
		if { $optgroup ne "" } {
		    append output "</optgroup>\n"
		}
		append output "<optgroup label=\"[ad_quotehtml $group]\">\n"
		set optgroup $group
	    }


	    append output " <option value=\"[template::util::quote_html $value]\""
	    if { [info exists values($value)] } {
		append output " selected=\"selected\""
	    }
	    append output ">$label</option>\n"


	}
	if { $optgroup ne {} } {
	    append output "</optgroup>\n"
	}
	append output "</select>"	
    }

    return $output
}

