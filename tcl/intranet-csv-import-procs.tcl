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

ad_proc -public im_csv_import_parser_no_change { 
    {-parser_args "" }
    arg 
} {
    Dummy parser without transformation
} {
    return [list $arg ""]
}

ad_proc -public im_csv_import_parser_project_nr { 
    {-parser_args "" }
    arg 
} {
    Returns a project_id from project_nr
} {
    if {[regexp {'} $arg match]} { 
       set err "Found a Project Nr with single quote"
       im_security_alert -location "im_csv_import_parser_project_nr" -message $err -value $arg 
       return [list $arg $err]
    }

    set sql "
	select	min(p.project_id)
	from	im_projects p
	where	p.project_nr = '$arg'
    "
    set project_id [db_string project_id_from_nr $sql -default ""]
    set err ""
    if {"" == $project_id} { set err "Didn't find project with project_nr='$arg'" }
    return [list $project_id $err]
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


ad_proc -public im_csv_import_parser_number_european {
    {-parser_args "" }
    arg 
} {
    Parses a European number format like '20.000,00' as twenty thousand 
} {
    set result [string map -nocase {"." ""} $arg]
    set result [string map -nocase {"," "."} $result]
    return [list $result ""]
}


ad_proc -public im_csv_import_parser_number_american {
    {-parser_args "" }
    arg 
} {
    Parses a European number format like '20.000,00' as twenty thousand 
} {
    set result [string map -nocase {"," ""} $result]
    return [list $result ""]
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

ad_proc -public im_csv_import_parser_hard_coded { 
    {-parser_args "" }
    arg 
} {
   Empty parser - returns the argument
} {
    return [list $arg ""]
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
    Returns a list of database columns for the specified object type.
} {
    # Get the list of super-types for object_type, including object_type
    # and remove "acs_object" from the list
    set super_types [im_object_super_types -object_type $object_type]
    set s [list]
    foreach t $super_types {
	if {$t == "acs_object"} { continue }
	lappend s $t
    }
    set super_types $s

    # ---------------------------------------------------------------
    # Get the list of tables associated with the object type and its super types

    set tables_sql "
	select	*
	from	(
		select	table_name, id_column, 1 as sort_order
		from	acs_object_types
		where	object_type in ('[join $super_types "', '"]')
	UNION
		select	table_name, id_column, 2 as sort_order
		from	acs_object_type_tables
		where	object_type in ('[join $super_types "', '"]')
		) t
	order by t.sort_order
    "

    set columns_sql "
	select	lower(column_name) as column_name
	from	user_tab_columns
	where	lower(table_name) = lower(:table_name)
    "

    set selected_columns {}
    set selected_tables {}
    set cnt 0
    db_foreach tables $tables_sql {

	if {[lsearch $selected_tables $table_name] >= 0} { 
	    ns_log Notice "im_csv_import_object_fields: found duplicate table: $table_name"
	    continue 
	}

	db_foreach columns $columns_sql {
	    if {[lsearch $selected_columns $column_name] >= 0} { 
		ns_log Notice "im_csv_import_object_fields: found ambiguous field: $table_name.$column_name"
		continue 
	    }
	    lappend selected_columns $column_name
	}

	lappend selected_tables $table_name
	incr cnt
    }

    return [lsort $selected_columns]
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
	im_project - im_risk - im_timesheet_task - im_ticket {
	    set parsers {
		no_change	"No Change"
		hard_coded	"Hard Coded Functionality"
		date_european	"European Date Parser (DD.MM.YYYY)"
		number_european	"European Number Parser (20.000,00)"
		date_american	"American Date Parser (MM/DD/YYYY)"
		number_american	"American Number Parser (20,000.00)"
		category	"Category Parser"
		cost_center	"Cost Center Parser"
		project_nr	"Project from Project Nr"
		project_name	"Project from Project Name"
	    }
	}
	default {
	    ad_return_complaint 1 "im_csv_import_parsers: Unknown object type '$object_type'"
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
    a list with:
    <ul>
    <li>The parser name,
    <li>the parser args and
    <li>the field name to map to
    </ul>
} {
    # --------------------------------------------------------
    # Check for static mapping
    set field_name_lower [string tolower $field_name]
    set static_mapping_lol {}
    catch {
	set static_mapping_lol [im_csv_import_guess_$object_type]
    }
    ns_log Notice "im_csv_import_guess_parser: static_mapping=$static_mapping_lol"
    foreach tuple $static_mapping_lol {
	set attribute_name [lindex $tuple 0]
	set pretty_name [lindex $tuple 1]
	set parser [lindex $tuple 2]
	set parser_args [lindex $tuple 3]
	if {$field_name_lower == [string tolower $pretty_name]} {
	    ns_log Notice "im_csv_import_guess_map: found statically encoded match with field_name=$field_name"
	    return [list $parser $parser_args $attribute_name]
	}
    }

    # --------------------------------------------------------
    # Hard Coded Mappings

    switch $object_type {
	im_project - im_timesheet_task - im_ticket {
	    switch $field_name {
		parent_nrs { return [list "hard_coded" "" ""] }
		customer_name { return [list "hard_coded" "" ""] }
		project_status { return [list "hard_coded" "" "project_status_id"] }
		project_type { return [list "hard_coded" "" "project_type_id"] }
		on_track_status { return [list "hard_coded" "" "on_track_status_id"] }
		customer_contact { return [list "" "" "company_contact_id"] }
		project_manager { return [list "hard_coded" "" "project_lead_id"] }
	    }
	}
    }


    # --------------------------------------------------------
    # Date parsers
    #
    # Abort if there are not enough values
    if {[llength $sample_values] >= 1} { 

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
	
	if {$date_european_p} { return [list "date_european" "" ""] }
	if {$date_american_p} { return [list "date_american" "" ""]}
    }


    # --------------------------------------------------------
    # Get the list of super-types for object_type, including object_type
    # and remove "acs_object" from the list
    set super_types [im_object_super_types -object_type $object_type]
    set s [list]
    foreach t $super_types {
	if {$t == "acs_object"} { continue }
	lappend s $t
    }
    set super_types $s

    ns_log Notice "im_csv_import_guess_parser: field_name=$field_name, super_types=$super_types"

    # --------------------------------------------------------
    # Parsing for DynFields
    #
    # There can be 0, 1 or multiple dynfields with the field_name,
    # unfortunately.
    set dynfield_sql "
	select	dw.widget as tcl_widget,
		dw.parameters as tcl_widget_parameters,
		substring(dw.parameters from 'category_type \"(.*)\"') as category_type,
		aa.attribute_name
	from	acs_attributes aa,
		im_dynfield_attributes da,
		im_dynfield_widgets dw
	where	aa.object_type in ('[join $super_types "','"]') and
		aa.attribute_id = da.acs_attribute_id and
		da.widget_name = dw.widget_name and
		(lower(aa.attribute_name) = lower(trim(:field_name)) OR
		lower(aa.attribute_name) = lower(trim(:field_name))||'_id'
		)
    "
    set result [list "" "" ""]
    set ttt_widget ""
    db_foreach dynfields $dynfield_sql {
	set ttt_widget $tcl_widget
	switch $tcl_widget {
	    "im_category_tree" {
		set result [list "category" $category_type $attribute_name]
	    }
	    "im_cost_center_tree" {
		set result [list "cost_center" "" $attribute_name]
	    }
	    default {
		# Default: No specific parser
		set result [list "" "" $attribute_name]
	    }
	}
    }

    ns_log Notice "im_csv_import_guess_parser: field_name=$field_name, tcl_widget=$ttt_widget => $result"
    return $result
}


# ---------------------------------------------------------------------
# Guess the most probable DynField for a column
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_guess_map {
    -object_type:required
    -field_name:required
    {-sample_values {}}
} {
    Returns the best guess for a DynField for the field.
} {
    set field_name_lower [string tolower $field_name]
    ns_log Notice "im_csv_import_guess_map: trying to guess attribute_name for field_name=$field_name_lower"

    set dynfield_sql "
	select  lower(aa.attribute_name) as attribute_name,
		lower(aa.pretty_name) as pretty_name,
		w.widget as tcl_widget,
		w.widget_name as dynfield_widget
	from	im_dynfield_attributes a,
		im_dynfield_widgets w,
		acs_attributes aa
	where	a.widget_name = w.widget_name and 
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = '$object_type'
	order by aa.sort_order, aa.attribute_id
    "

    # Check if the header name is the attribute_name of a DynField
    set dynfield_attribute_names [util_memoize [list db_list otype_dynfields "select attribute_name from ($dynfield_sql) t"]]
    ns_log Notice "im_csv_import_guess_map: attribute_names=$dynfield_attribute_names"
    if {[lsearch $dynfield_attribute_names $field_name_lower] >= 0} {
	ns_log Notice "im_csv_import_guess_map: found attribute_name match with field_name=$field_name"
	return $field_name_lower
    }

    # Check for a pretty_name of a DynField
    set dynfield_pretty_names [util_memoize [list db_list otype_dynfields "select pretty_name from ($dynfield_sql) t"]]
    ns_log Notice "im_csv_import_guess_map: pretty_names=$dynfield_pretty_names"
    set idx [lsearch $dynfield_pretty_names $field_name_lower]
    if {$idx >= 0} {
	ns_log Notice "im_csv_import_guess_map: found pretty_name match with field_name=$field_name"
	return [lindex $dynfield_attribute_names $idx]
    }

    # Check for static mapping
    set static_mapping_lol {}
    catch {
	set static_mapping_lol [im_csv_import_guess_$object_type]
    }
    ns_log Notice "im_csv_import_guess_map: static_mapping=$static_mapping_lol"
    foreach tuple $static_mapping_lol {
	set attribute_name [lindex $tuple 0]
	set pretty_name [lindex $tuple 1]
	set parser [lindex $tuple 2]
	set parser_args [lindex $tuple 3]
	if {$field_name_lower == [string tolower $pretty_name]} {
	    ns_log Notice "im_csv_import_guess_map: found statically encoded match with field_name=$field_name"
	    return $attribute_name
	} else {
	    ns_log Notice "im_csv_import_guess_map: $pretty_name!=$field_name_lower"
	}
    }

    ns_log Notice "im_csv_import_guess_map: Did not find any match with a DynField for field_name=$field_name"
    ns_log Notice "im_csv_import_guess_map:"
    return ""
}


# ---------------------------------------------------------------------
# Default mapping for built-in ]po[ reports
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_guess_im_risk { } {} {
    set mapping {
	{risk_name "Risk Name" no_change ""}
	{risk_project_id "Project" project_nr ""}
	{risk_status_id "Status" category "Intranet Risk Status"}
	{risk_type_id "Type" category "Intranet Risk Type"}
	{risk_description "Description" no_change ""}
	{risk_impact "Impact" number_european ""}
	{risk_probability_percent "Probability" number_european ""}
    }
    return $mapping
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



# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_check_list_of_lists {
    lol
} {
    Check that the parameter is a list of lists with all
    line having the same length.
    Returns a HTML string of LI error messages or an emtpy
    string if there was no issue.
} {
    set length_list [list]
    set min_length 1000
    set max_length 0
    set result ""
    foreach line $lol {
	set length [llength $line]
	if {$length > $max_length} { set max_length $length }
	if {$length < $min_length} { set min_length $length }
	lappend length_list $length
    }

    set ctr 0
    foreach line $lol {
	set length [llength $line]
	if {$length < 4} { 
	    append result "<li>Line #$ctr: Found a (nearly) empty line with only $length columns.\n"
	}
	if {$length < $max_length} { 
#	    append result "<li>Line #$ctr: Found a line with $length elements which doesn't match the $max_length width.\n"
	}

	incr ctr
    }

    return $result
}