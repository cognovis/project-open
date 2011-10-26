# /packages/intranet-csv-import/www/import-im_project.tcl
#

ad_page_contract {
    Starts the analysis process for the file imported
    @author frank.bergmann@project-open.com

    @param mapping_name: Should we store the current mapping in the DB for future use?
    @param column: Name of the CSV column
    @param map: Name of the ]po[ object attribute
    @param parser: Converter for CSV data type -> ]po[ data type
} {
    { return_url "" }
    { upload_file "" }
    { import_filename "" }
    { mapping_name "" }
    { ns_write_p 1 }
    column:array
    map:array
    parser:array
    parser_args:array
}

# ---------------------------------------------------------------------
# Default & Security
# ---------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-cvs-import.Upload_Objects "Upload Objects"]
set context_bar [im_context_bar "" $page_title]
set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$admin_p} {
    ad_return_complaint 1 "Only administrators have the right to import objects"
    ad_script_abort
}


# ---------------------------------------------------------------------
# Check and open the file
# ---------------------------------------------------------------------

if {![file readable $import_filename]} {
    ad_return_complaint 1 "Unable to read the file '$import_filename'. <br>
    Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}

set encoding "utf-8"
if {[catch {
    set fl [open $import_filename]
    fconfigure $fl -encoding $encoding
    set lines_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $import_filename:<br><pre>\n$err</pre>"
    ad_script_abort
}


# Extract the header line from the file
set lines [split $lines_content "\n"]
set separator [im_csv_guess_separator $lines]
set lines_len [llength $lines]
set header [lindex $lines 0]
set header_fields [im_csv_split $header $separator]
set header_len [llength $header_fields]
set values_list_of_lists [im_csv_get_values $lines_content $separator]


# ------------------------------------------------------------
# Get DynFields

set dynfield_sql {
	select distinct
		aa.attribute_name,
		aa.object_type,
		w.parameters,
		w.widget as tcl_widget,
		substring(w.parameters from 'category_type "(.*)"') as category_type
	from	im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where	a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type in ('im_project', 'im_timesheet_task') and
		(also_hard_coded_p is null OR also_hard_coded_p = 'f')
}

set attribute_names [db_list attribute_names "
	select	distinct
		attribute_name
	from	($dynfield_sql) t
	order by attribute_name
"]

# ------------------------------------------------------------
# Render Result Header

if {$ns_write_p} {
    ad_return_top_of_page "
	[im_header]
	[im_navbar]
    "
}

# ------------------------------------------------------------

set cnt 1
foreach csv_line_fields $values_list_of_lists {
    incr cnt

    if {$ns_write_p} { ns_write "</ul><hr><ul>\n" }
    if {$ns_write_p} { ns_write "<li>Starting to parse line $cnt\n" }

    # Preset values, defined by CSV sheet:
    set project_name		""
    set project_nr		""
    set project_path		""
    set customer_name		""
    set customer_id		""
    set parent_nrs		""
    set parent_id		""
    set project_status_id	""
    set project_type_id	 	""

    set project_lead_id	 	""
    set start_date		""
    set end_date		""
    set percent_completed	""
    set on_track_status 	""

    set project_budget		""
    set project_budget_currency	""
    set project_budget_hours	""

    set description		""
    set note			""

    set company_contact_id	""
    set company_project_nr	""
    set confirm_date		""
    set expected_quality_id	""
    set final_company		""
    set milestone_p		""
    set project_priority	""
    set sort_order		""
    set source_language_id	""
    set subject_area_id		""
    set template_p		""

    set cost_center		""
    set uom			""
    set planned_units		""
    set billable_units		""
    set priority		""
    set sort_order		""

    foreach attribute_name $attribute_names {
	set $attribute_name	""
    }

    # -------------------------------------------------------
    # Extract variables from the CSV file
    #
    set var_name_list [list]
    for {set j 0} {$j < $header_len} {incr j} {

	set var_name [string trim [lindex $header_fields $j]]
	if {"" == $var_name} {
	    # No variable name - probably an empty column
	    continue
	}

	set var_name [string tolower $var_name]
	set var_name [string map -nocase {" " "_" "\"" "" "'" "" "/" "_" "-" "_" "\[" "(" "\{" "(" "\}" ")" "\]" ")"} $var_name]
	lappend var_name_list $var_name
	ns_log notice "upload-companies-2: varname([lindex $header_fields $j]) = $var_name"

	set var_value [string trim [lindex $csv_line_fields $j]]
	set var_value [string map -nocase {"\"" "'" "\[" "(" "\{" "(" "\}" ")" "\]" ")"} $var_value]
	if {[string equal "NULL" $var_value]} { set var_value ""}

	# replace unicode characters by non-accented characters
	# Watch out! Does not work with Latin-1 characters
	set var_name [im_mangle_unicode_accents $var_name]

	set cmd "set $var_name \"$var_value\""
	ns_log Notice "upload-companies-2: cmd=$cmd"
	set result [eval $cmd]
    }

    # -------------------------------------------------------
    # Transform the variables
    set i 0
    foreach varname $var_name_list {
	set p $parser($i)
	set p_args $parser_args($i)
	switch $p {
	    no_change { }
	    default {
		set proc_name "im_csv_import_parser_$p"
		if {[catch {
		    set val [set $varname]
		    if {"" != $val} {
			    set result [$proc_name -parser_args $p_args $val]
			    set res [lindex $result 0]
			    set err [lindex $result 1]
			    if {"" != $err} {
				if {$ns_write_p} { 
				    ns_write "<li><font color=brown>Warning: Error parsing field='[set $varname]' using parser '$p':<pre>$err</pre></font>\n" 
				}
			    }
			    set $varname $res
		    }
		} err_msg]} {
		    if {$ns_write_p} { 
			ns_write "<li><font color=brown>Warning: Error parsing field='[set $varname]' using parser '$p':<pre>$err_msg</pre></font>" 
		    }
		}
	    }
	}

	incr i
    }
    

    # -------------------------------------------------------
    # Specific field transformations

    # project_name needs to be there
    if {"" == $project_name} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found an empty 'Project Name' in line $cnt.<br>
	        Please correct the CSV file. Every projects needs to have a unique Project Name.</font>\n"
	}
	continue
    }

    # project_nr needs to be there
    if {"" == $project_nr} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found an empty 'Project Nr' in line $cnt.<br>
	    Please correct the CSV file. Every project needs to have a unique Project Nr.</font>\n"
	}
	continue
    }

    # parent_nrs contains a space separated list
    if {[catch {
	set result [im_csv_import_convert_project_parent_nrs $parent_nrs]
    } err_msg]} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: We have found an error parsing Parent NRs '$parent_nrs'.<pre>\n$err_msg</pre>" }
	continue
    }
    set parent_id [lindex $result 0]
    set err [lindex $result 1]
    if {"" != $err} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: <pre>$err</pre></font>\n" }
	continue
    }

    # Status is a required field
    set project_status_id [im_id_from_category $project_status "Intranet Project Status"]
    if {"" == $project_status_id} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find project status '$project_status', using default status 'Open'</font>\n" }
	set project_status_id [im_project_status_open]
    }

    # Type is a required field
    set project_type_id [im_id_from_category [list $project_type] "Intranet Project Type"]
    if {"" == $project_type_id} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find project type '$project_type', using default type 'Other'</font>\n" }
	set project_type_id [im_project_type_other]
    }

    # On track status can be NULL without problems
    set on_track_status_id [im_id_from_category [list $on_track_status] "Intranet Project On Track Status"]

    # Priority has been introduced by department planner...
    set project_priority_id [im_id_from_category [list $project_priority] "Intranet Department Planner Project Priority"]

    # customer_id
    if {"" == $customer_id } { 
	set customer_id [db_string cust "select company_id from im_companies where lower(company_name) = trim(lower(:customer_name))" -default ""] 
    }
    if {"" == $customer_id } { 
	set customer_id [db_string cust "select company_id from im_companies where lower(company_path) = trim(lower(:customer_name))" -default ""] 
    }
    if {"" == $customer_id } { 
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: Didn't find customer for '$customer_name'.<br>
	    Every projects needs a valid customer. Please correct the CSV file.</font>\n"
	}
	continue
    }

    set project_lead_id [im_id_from_user_name $project_manager]
    if {"" == $project_lead_id && "" != $project_manager} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find project manager '$project_manager'.</font>\n" }
    }

    set company_contact_id [im_id_from_user_name $customer_contact]
    if {"" == $company_contact_id && "" != $customer_contact} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find customer contact '$customer_contact'.</font>\n"	}
    }


    # -------------------------------------------------------
    # Check if the project already exists

    set parent_id_sql "= $parent_id"
    if {"" == $parent_id} { 
	set parent_id_sql "is null"
    }

    set project_id [db_string project_id "
	select	project_id
	from	im_projects p
	where	p.parent_id $parent_id_sql and
		(	lower(trim(project_name)) = lower(trim(:project_name))
		OR	lower(trim(project_nr)) = lower(trim(:project_nr))
		)
    " -default ""]

    # Check for problems with project_path
    set project_path_exists_p [db_string project_path_existis_p "
	select	count(*)
	from	im_projects p
	where	p.parent_id $parent_id_sql and
		p.project_id != :project_id and
		lower(trim(project_path)) = lower(trim(:project_path))
    "]
    if {$project_path_exists_p} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: project_path='$project_path' already exists with the parent '$parent_id'</font>" }
	continue
    }

    # Project Path is the same as the if not specified otherwise
    if {"" == $project_path} { set project_path $project_nr }

    # Create a new project if necessary
    if {"" == $project_id} {

	if {$ns_write_p} { ns_write "<li>Going to create project: name='$project_name', nr='$project_nr'\n" }
	if {[catch {
		set project_id [project::new \
			    -project_name	$project_name \
			    -project_nr		$project_nr \
			    -project_path	$project_path \
			    -company_id		$customer_id \
			    -parent_id		$parent_id \
			    -project_type_id	$project_type_id \
			    -project_status_id	$project_status_id \
			   ]
	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=red>Error: Creating new project:<br><pre>$err_msg</pre></font>\n" }
	    continue	    
	}

    } else {
	if {$ns_write_p} { ns_write "<li>Project already exists: name='$project_name', nr='$project_nr', id='$project_id'\n" }
    }

    if {$ns_write_p} { ns_write "<li>Going to update the project.\n" }
    if {[catch {
	db_dml update_project "
		update im_projects set
			project_name		= :project_name,
			project_nr		= :project_nr,
			project_path		= :project_path,
			company_id		= :customer_id,
			parent_id		= :parent_id,
			project_status_id	= :project_status_id,
			project_type_id		= :project_type_id,
			project_lead_id		= :project_lead_id,
			start_date		= :start_date,
			end_date		= :end_date,
			percent_completed	= :percent_completed,
			on_track_status_id	= :on_track_status_id,
			project_budget		= :project_budget,
			project_budget_currency	= :project_budget_currency,
			project_budget_hours	= :project_budget_hours,
			project_priority_id	= :project_priority_id,
			company_contact_id	= :company_contact_id,
			company_project_nr	= :customer_project_nr,
			note			= :note,
			description		= :description
		where
			project_id = :project_id
	"
    } err_msg]} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: Error updating project:<br><pre>$err_msg</pre></font>" }
	continue	    
    }

    
    # -------------------------------------------------------
    # Make sure there is an entry in im_timesheet_tasks if the project is of type task
    if {$project_type_id == [im_project_type_task]} {

	set material_id ""
	if {"" != $material} {
	    set material_id [db_string material_lookup "
		select	min(material_id)
		from	im_materials
		where	(  lower(trim(material_nr)) = lower(trim(:material)) 
			OR lower(trim(material_name)) = lower(trim(:material))
			)
	    " -default ""]
	    if {"" == $material_id} {
		if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find material '$material', using 'Default'.</font>\n" }
	    }
	}
	if {"" == $material_id} {
	    set material_id [im_material_default_material_id]
	}
	
	# Task Cost Center
	set cost_center_id [db_string cost_center_lookup "
		select	min(cost_center_id)
		from	im_cost_centers
		where	(  lower(trim(cost_center_name)) = lower(trim(:cost_center)) 
			OR lower(trim(cost_center_label)) = lower(trim(:cost_center))
			OR lower(trim(cost_center_code)) = lower(trim(:cost_center))
			)
	" -default ""]
	if {"" == $cost_center_id && "" != $cost_center} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find cost_center '$cost_center'.</font>\n" }
	}

	# Task UoM
	if {"" == $uom} { set uom "Hour" }
	set uom_id [im_id_from_category [list $uom] "Intranet UoM"]
	if {"" == $uom_id} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find UoM '$uom', using default 'Hour'</font>\n" }
	    set uom_id [im_uom_hour]
	}

	set task_exists_p [db_string task_exists_p "
		select	count(*)
		from	im_timesheet_tasks
		where	task_id = :project_id
	"]

	if {!$task_exists_p} {
	    db_dml task_insert "
		insert into im_timesheet_tasks (
			task_id,
			material_id,
			uom_id
		) values (
			:project_id,
			:material_id,
			:uom_id
		)
	    "
	    db_dml make_project_to_task "
		update acs_objects
		set object_type = 'im_timesheet_task'
		where object_id = :project_id
	    "
	}
	db_dml update_task "
		update im_timesheet_tasks set
			material_id	= :material_id,
			uom_id		= :uom_id,
			planned_units	= :planned_units,
			billable_units	= :billable_units,
			cost_center_id	= :cost_center_id
		where
			task_id = :project_id
	"
    }


    # -------------------------------------------------------
    # Import DynFields    
    set project_dynfield_updates {}
    set task_dynfield_updates {}
    db_foreach store_dynfiels $dynfield_sql {
	switch $object_type {
	    im_project {
		lappend project_dynfield_updates "$attribute_name = :$attribute_name"
	    }
	    im_timesheet_task {
		lappend task_dynfield_updates "$attribute_name = :$attribute_name"
	    }
	}
    }

    if {$ns_write_p} { ns_write "<li>Going to update im_project DynFields.\n" }
    if {"" != $project_dynfield_updates} {
	set project_update_sql "
		update im_projects set
		[join $project_dynfield_updates ",\n\t\t"]
		where project_id = :project_id
	"
	if {[catch {
	    db_dml project_dynfield_update $project_update_sql
	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Error updating im_project dynfields:<br><pre>$err_msg</pre></font>" }
	}
    }

    if {$ns_write_p} { ns_write "<li>Going to update im_timesheet_task DynFields.\n" }
    if {"" != $task_dynfield_updates} {
	set task_update_sql "
		update im_timesheet_tasks set
		[join $task_dynfield_updates ",\n\t\t"]
		where task_id = :project_id
	"
	if {[catch {
            db_dml task_dynfield_update $task_update_sql
	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Error updating im_timesheet_task dynfields:<br><pre>$err_msg</pre></font>" }
	}

    }

}


if {$ns_write_p} {
    ns_write "</ul>\n"
    ns_write "<p>\n"
    ns_write "<A HREF=$return_url>Return to Project Page</A>\n"
}

# ------------------------------------------------------------
# Render Report Footer

if {$ns_write_p} {
    ns_write [im_footer]
}


