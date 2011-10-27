# /packages/intranet-cvs-import/tcl/intranet-cvs-import-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------------
# Aux functions
# ---------------------------------------------------------------------

ad_proc -public im_id_from_user_name { name } {
    Checks for a user with the given name
} {
    set user_id [db_string uid "
	select	min(user_id)
	from	users
	where	lower(trim(username)) = lower(trim(:name))
    " -default ""]

    if {"" == $user_id} {
	set user_id [db_string uid "
		select	min(person_id)
		from	persons
		where	lower(trim(im_name_from_user_id(person_id))) = lower(trim(:name))
	" -default ""]
    }

    return $user_id
}

ad_proc -public im_csv_import_parser_date_european { 
    {-parser_args "" }
    arg 
} {
    Parses a European date format like '08.06.2011' as the 8th of June, 2011
} {
    if {[regexp {^(.+)\.(.+)\.(....)$} $arg match dom month year]} { 
	if {1 == [string length $dom]} { set dom "0$dom" }
	if {1 == [string length $month]} { set dom "0$month" }
	return [list "$year-$month-$dom" ""] 
    }
    return [list "" "Error parsing European date format '$arg': expected 'dd.mm.yyyy'"]
}


ad_proc -public im_csv_import_parser_date_american { 
    {-parser_args "" }
    arg 
} {
    Parses a American date format like '12/31/2011' as the 31st of December, 2011
} {
    if {[regexp {^(.+)\/(.+)\/(....)$} $arg match month dom year]} { 
	if {1 == [string length $dom]} { set dom "0$dom" }
	if {1 == [string length $month]} { set dom "0$month" }
	return [list "$year-$month-$dom" ""] 
    }
    return [list "" "Error parsing American date format '$arg': expected 'dd.mm.yyyy'"]
}

ad_proc -public im_csv_import_parser_category { 
    {-parser_args "" }
    arg 
} {
    Parses a category into a category_id
} {
    # Empty input - empty output
    if {"" == $arg} { return [list "" ""] }

    # Parse the category
    set result [im_id_from_category $arg $parser_args]
    if {"" == $result} {
	return [list "" "Category parser: We did not find a value='$arg' in category type '$parser_args'."]
    } else {
	return [list $result ""]
    }
}

ad_proc -public im_csv_import_parser_cost_center { 
    {-parser_args "" }
    arg 
} {
    Parses a cost center into a cost_center_id
} {
    # Empty input - empty output
    if {"" == $arg} { return [list "" ""] }

    # Parse the category
    set arg [string trim [string tolower $arg]]
    set ccids [db_list ccid1 "
	select	cost_center_id
	from	im_cost_centers
	where	lower(cost_center_code) = :arg OR 
		lower(cost_center_label) = :arg OR 
		lower(cost_center_name) = :arg order by cost_center_id
    "]
    set result [lindex $ccids 0]
    if {"" == $result} {
	return [list "" "Cost Center parser: We did not find any cost center with label, code or name matching the value='$arg'."]
    } else {
	return [list $result ""]
    }
}

# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_csv_import_label_from_object_type {
    -object_type:required
} {
    Returns the main navbar lable for the object_type
} {
    switch $object_type {
	im_company { return "companies" }
	im_project { return "projects" }
	person { return "users" }
	default { return "" }
    }
}

# ---------------------------------------------------------------------
# Available Fields per Object Type
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_object_fields {
    -object_type:required
} {
    Returns the main navbar lable for the object_type
} {
    switch $object_type {
	im_project {
	    set object_fields {
		customer_name
		parent_nrs
		project_nr
		project_name
		project_status
		project_type
		start_date
		end_date
		customer_contact
		on_track_status
		percent_completed
		project_manager
		project_priority
		program
		milestone_p
		description
		note
		material
		uom
		planned_units
		billable_units
		cost_center_code
		timesheet_task_priority
		sort_order
		project_budget
		project_budget_currency
		project_budget_hours
		presales_probability
		presales_value
		project_path
		confirm_date
		source_language
		subject_area
		final_company
		expected_quality
		customer_project_nr
	    }
	}
	default {
	    ad_return_complaint 1 "Unknown object type '$object_type'"
	    ad_script_abort
	}
    }

    set dynfield_sql "
	select	aa.*,
		a.*,
		w.*
	from	im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where	a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type in ('im_project', 'im_timesheet_task') and
		(also_hard_coded_p is null OR also_hard_coded_p = 'f')
    "
    db_foreach dynfields $dynfield_sql {
	lappend object_fields $attribute_name
    }    

    return $object_fields
}


# ---------------------------------------------------------------------
# Available Parsers
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_parsers {
    -object_type:required
} {
    Returns the list of available parsers
} {
    switch $object_type {
	im_project {
	    set parsers {
		no_change	"No Change"
		date_european	"European Date Parser (DD.MM.YYYY)"
		date_american	"American Date Parser (MM/DD/YYYY)"
		category	"Category Parser"
		cost_center	"Cost Center"
	    }
	}
	default {
	    ad_return_complaint 1 "Unknown object type '$object_type'"
	    ad_script_abort
	}
    }
    return $parsers
}



# ---------------------------------------------------------------------
# Guess the most appropriate parser for a column
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_guess_parser {
    {-sample_values {}}
    -object_type:required
    -field_name:required
} {
    Returns the best guess for a parser for the given field as
    a list with 1. the parser name and 2. the parser args
} {
    # --------------------------------------------------------
    # Abort if there are not enough values
    if {[llength $sample_values] < 2} { return [list "" ""] }


    # --------------------------------------------------------
    # Date parsers
    #
    set date_european_p 1
    set date_american_p 1
    set number_plain_p 1
    set number_european_p 1
    set number_american_p 1

    # set the parserst to 0 if one of the values doesn't fit
    foreach val $sample_values { 
	if {![regexp {^(.+)\.(.+)\.(....)$} $val match]} { set date_european_p 0 } 
	if {![regexp {^(.+)\/(.+)\/(....)$} $val match]} { set date_american_p 0 } 
	if {![regexp {^[0-9]+$} $val match]} { set number_plain 0 } 
    }

    if {$date_european_p} { return [list "date_european" ""] }
    if {$date_american_p} { return [list "date_american" ""]}


    # --------------------------------------------------------
    # Parsing for DynFields
    if {[db_0or1row dynfield_info {
	select	dw.widget as tcl_widget,
		dw.parameters as tcl_widget_parameters,
		substring(dw.parameters from 'category_type "(.*)"') as category_type
	from	acs_attributes aa,
		im_dynfield_attributes da,
		im_dynfield_widgets dw
	where	aa.object_type = :object_type and
		aa.attribute_name = :field_name and
		aa.attribute_id = da.acs_attribute_id and
		da.widget_name = dw.widget_name
    }]} {
	switch $tcl_widget {
	    "im_category_tree" {
		return [list "category" $category_type]		
	    }
	    "im_cost_center_tree" {
		return [list "cost_center" ""]		
	    }
	    default {
		# Default: No specific parser
		return [list "" ""]
	    }
	}
    }

    return [list "" ""]
}


# ---------------------------------------------------------------------
# Convert the list of parent_nrs into the parent_id
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_convert_project_parent_nrs { 
    {-parent_id ""}
    parent_nrs 
} {
    Returns {parent_id err}
} {
    ns_log Notice "im_csv_import_convert_project_parent_nrs -parent_id $parent_id $parent_nrs"

    # Recursion end - just return the parent.
    if {"" == $parent_nrs} { return [list $parent_id ""] }
    
    # Lookup the first parent_nr below the current parent_id
    set parent_nr [lindex $parent_nrs 0]
    set parent_nrs [lrange $parent_nrs 1 end]

    set parent_sql "= $parent_id"
    if {"" == $parent_id} { set parent_sql "is null" }

    set parent_id [db_string pid "
	select	project_id
	from	im_projects
	where	parent_id $parent_sql and
		lower(project_nr) = lower(:parent_nr)
    "]

    if {"" == $parent_id} {
	return [list "" "Didn't find project with project_nr='$project_nr' and parent_id='$parent_id'"]
    }

    return [im_csv_import_convert_project_parent_nrs -parent_id $parent_id $parent_nrs]
}