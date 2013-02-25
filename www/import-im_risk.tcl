# /packages/intranet-csv-import/www/import-im_risk.tcl
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

# ad_return_complaint 1 "<pre>[array get column]<br>[array get map]<br>[array get parser]<br>[array get parser_args]<br>$header_fields</pre>"



# ------------------------------------------------------------
# Get DynFields

# Determine the list of actually available fields.
set mapped_vars [list "''"]
foreach k [array names map] {
    lappend mapped_vars "'$map($k)'"
}

set dynfield_sql "
	select distinct
		aa.attribute_name,
		aa.object_type,
		aa.table_name,
		w.parameters,
		w.widget as tcl_widget,
		substring(w.parameters from 'category_type \"(.*)\"') as category_type
	from	im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where	a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type in ('im_risk') and
		(also_hard_coded_p is null OR also_hard_coded_p = 'f') and
		-- Only overwrite DynFields specified in the mapping
		aa.attribute_name in ([join $mapped_vars ","])
"

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

    if {[llength $csv_line_fields] < 4} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We found a row with only [llength $csv_line_fields] columns.<br>
	        This is probabily because of a multi-line field in the row before.<br>Please correct the CSV file.</font>\n"
	}
	continue
    }


    # Preset values, defined by CSV sheet:
    set risk_name		""
    set risk_project_id		""
    set risk_status_id		""
    set risk_type_id	 	""
    set risk_description	""
    set risk_impact		""
    set risk_probability_percent ""

    foreach attribute_name $attribute_names {
	set $attribute_name	""
    }

    # -------------------------------------------------------
    # Extract variables from the CSV file and write them to local variables
    # 
    # column:   	4 Impact 0 Project 5 Type 1 {Risk Name} 6 Status 2 {Risk Value} 7 Description 3 Probability
    # map:      	4 risk_impact 0 risk_project_id 5 risk_type_id 1 risk_name 6 risk_status_id 2 {} 7 risk_description 3 risk_probability_percent
    # parser:   	4 no_change 0 no_change 5 no_change 1 no_change 6 no_change 2 no_change 7 no_change 3 no_change
    # parser_args:   	4 {} 0 {} 5 {} 1 {} 6 {} 2 {} 7 {} 3 {}
    #
    foreach j [array names column] {

	# Extract values
	set pretty_var_name $column($j)
	set target_var_name $map($j)
	set p $parser($j)
	set p_args $parser_args($j)

	# Extract the value from the CSV line
	set var_value [string trim [lindex $csv_line_fields $j]]

	# There is a im_csv_import_parser_* proc for every parser.
	set proc_name "im_csv_import_parser_$p"
	if {"" != $var_value} {
	    if {[catch {
		set result [$proc_name -parser_args $p_args $var_value]
		set var_value [lindex $result 0]
		set err [lindex $result 1]
		ns_log Notice "import-im_project: Parser: '$p -args $p_args $var_value' -> $target_var_name=$var_value, err=$err"
		if {"" != $err} {
		    if {$ns_write_p} { 
			ns_write "<li><font color=brown>Warning: Error parsing field='$target_var_name' using parser '$p':<pre>$err</pre></font>\n" 
		    }
		}
	    } err_msg]} {
		if {$ns_write_p} { 
		    ns_write "<li><font color=brown>Warning: Error parsing field='$target_var_name' using parser '$p':<pre>$err_msg</pre></font>" 
		}
	    }
	}
	set $target_var_name $var_value
    }

    
    # -------------------------------------------------------
    # Specific field transformations

    # risk_name needs to be there
    if {"" == $risk_name} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found an empty 'Risk Name' in line $cnt.<br>
	        Please correct the CSV file. Every risks needs to have a unique Risk Name.</font>\n"
	}
	continue
    }

    # risk_project_id needs to be there, it's part of the primary key
    if {"" == $risk_project_id} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found an empty 'Project' in line $cnt.<br>
	    Please correct the CSV file. Every risk needs to be associated with a project, <br>
	    and the project needs to be identified by a Project Nr..</font>\n"
	}
	continue
    }
    if {![string is integer $risk_project_id]} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found a bad value '$risk_project_id' for 'Project' in line $cnt.<br>
	    Please check that you are using the 'Project from Project Nr' or 'Project from Project Name' parser.</font>"
	}
	continue
    }

    # Status is a required field
    if {"" == $risk_status_id} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find risk status '$risk_status_id', using default status 'Open'</font>\n" }
	set risk_status_id [im_risk_status_open]
    }

    # Type is a required field
    if {"" == $risk_type_id} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find risk type '$risk_type_id', using default type 'Other'</font>\n" }
	set risk_type_id [im_risk_type_risk]
    }

    # -------------------------------------------------------
    # Check if the risk already exists
    #
    set risk_id [db_string risk_id "
	select	min(risk_id)
	from	im_risks r
	where	r.risk_project_id = :risk_project_id and
		lower(trim(r.risk_name)) = lower(trim(:risk_name))
    " -default ""]

    # Create a new risk if necessary
    if {"" == $risk_id} {
	if {$ns_write_p} { ns_write "<li>Going to create risk: name='$risk_name', project_id=='$risk_project_id'\n" }
	if {[catch {
	    set risk_id [db_string new_risk "
		select im_risk__new(
			null,				-- risk_id  default null
			'im_risk',			-- object_type default im_risk
			now()::timestamptz,		-- creation_date default now()
			:current_user_id::integer,	-- creation_user default null
			'[ad_conn peeraddr]',		-- creation_ip default null
			null::integer,			-- context_id default null
	
			:risk_project_id::integer,	-- risk container project
			:risk_status_id::integer,	-- active or inactive or for WF stages
			:risk_type_id::integer,		-- user defined type of risk. Determines WF.
			:risk_name			-- Unique name of risk per project
		)
	    "]

	    # Write Audit Trail
	    im_audit -object_id $risk_id -action after_create

	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=red>Error: Creating new risk:<br><pre>$err_msg</pre></font>\n" }
	    continue	    
	}

    } else {
	if {$ns_write_p} { ns_write "<li>Risk already exists: name='$risk_name', id='$risk_id'\n" }
    }

    if {$ns_write_p} { ns_write "<li>Going to update the risk.\n" }
    if {[catch {
	db_dml update_risk "
		update im_risks set
			risk_description		= :risk_description
		where
			risk_id = :risk_id
	"
    } err_msg]} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: Error updating risk:<br><pre>$err_msg</pre></font>" }
	continue	    
    }


    # -------------------------------------------------------
    # Import DynFields    
    set risk_dynfield_updates {}
    set task_dynfield_updates {}
    array unset attributes_hash
    array set attributes_hash {}
    db_foreach store_dynfiels $dynfield_sql {
	ns_log Notice "import-im_risk: name=$attribute_name, otype=$object_type, table=$table_name"

	# Avoid storing attributes multipe times into the same table.
	# Sub-types can have the same attribute defined as the main type, so duplicate
	# DynField attributes are OK.
	set key "$attribute_name-$table_name"
	if {[info exists attributes_hash($key)]} {
	    ns_log Notice "import-im_risk: name=$attribute_name already exists."
	    continue
	}
	set attributes_hash($key) $table_name
	lappend risk_dynfield_updates "$attribute_name = :$attribute_name"
    }

    if {$ns_write_p} { ns_write "<li>Going to update im_risk DynFields.\n" }
    if {"" != $risk_dynfield_updates} {
	set risk_update_sql "
		update im_risks set
		[join $risk_dynfield_updates ",\n\t\t"]
		where risk_id = :risk_id
	"
	if {[catch {
	    db_dml risk_dynfield_update $risk_update_sql
	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Error updating im_risk dynfields:<br><pre>$err_msg</pre></font>" }
	}
    }

    if {$ns_write_p} { ns_write "<li>Going to write audit log.\n" }
    im_audit -object_id $risk_id -action after_update

}


if {$ns_write_p} {
    ns_write "</ul>\n"
    ns_write "<p>\n"
    ns_write "<A HREF=$return_url>Return to Risk Page</A>\n"
}

# ------------------------------------------------------------
# Render Report Footer

if {$ns_write_p} {
    ns_write [im_footer]
}


