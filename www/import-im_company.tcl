# /packages/intranet-csv-import/www/import-im_company.tcl

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
		aa.object_type in ('im_company') and
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


    # im_company
    set company_name			""
    set company_path			""
    set company_status_id		""
    set company_type_id	 		""
    set note				""
    set company_id			""
    set company_name			""
    set company_path			""
    set main_office_id			""
    set deleted_p			""
    set crm_status_id			""
    set primary_contact_id		""
    set accounting_contact_id		""
    set note				""
    set referral_source			""
    set annual_revenue_id		""
    set status_modification_date 	""
    set old_company_status_id		""
    set billable_p			""
    set site_concept			""
    set manager_id			""
    set contract_value			""
    set start_date			""
    set vat_number			""
    set default_vat			""
    set default_invoice_template_id	""
    set default_payment_method_id	""
    set default_payment_days		""
    set default_bill_template_id	""
    set default_po_template_id		""
    set default_delnote_template_id	""
    set default_quote_template_id	""
    set default_tax			""
    set default_pm_fee_perc		""
    set default_surcharge_perc		""
    set default_discount_perc		""

    # im_office
    set phone				""
    set fax				""
    set address_line1			""
    set address_line2			""
    set address_city			""
    set address_state			""
    set address_postal_code		""
    set address_country_code		""
    set contact_person_id		""

    # Generic attributes
    foreach attribute_name $attribute_names {
	set $attribute_name	""
    }

    # -------------------------------------------------------
    # Extract variables from the CSV file and write them to local variables
    #
    # column:   	4 Impact 0 Project 5 Type 1 {Company Name} 6 Status 2 {Company Value} 7 Description 3 Probability
    # map:      	4 company_impact 0 company_project_id 5 company_type_id 1 company_name 6 company_status_id 2 {} 7 company_description 3 company_probability_percent
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

    # company_name needs to be there
    if {"" == $company_name} {
	if {$ns_write_p} {
	    ns_write "<li><font color=red>Error: We have found an empty 'Company Name' in line $cnt.<br>
	        Please correct the CSV file. Every companys needs to have a unique Company Name.</font>\n"
	}
	continue
    }

    if {"" == $company_path} {
	if {$ns_write_p} {
	    ns_write "<li><font color=brown>Warning We have found an empty 'Company Path' in line $cnt</font>"
	}
	set company_path [im_mangle_user_group_name $company_name]
    }

    # Status is a required field
    if {"" == $company_status_id} {
	if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Didn't find company status '$company_status_id', using default status 'Open'</font>\n" }
	set company_status_id [im_company_status_active]
    }

    # Type is a required field
    if {"" == $company_type_id} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: Didn't find company type '$company_type_id'.</font>\n" }
	continue
    }

    set office_name "$company_name [_ intranet-core.Main_Office]"
    set office_path "$company_path"

    # -------------------------------------------------------
    # Check if the company already exists
    #
    set company_id [db_string company_id "
	select	min(company_id)
	from	im_companies r
	where	lower(trim(r.company_name)) = lower(trim(:company_name)) OR
                lower(trim(r.company_path)) = lower(trim(:company_path))
    " -default ""]

    # Create a new company if necessary
    if {"" == $company_id} {
	if {$ns_write_p} { ns_write "<li>Going to create company: name='$company_name'\n" }

	if {[catch {

	    set company_id [im_new_object_id]

	    set main_office_id [db_string office_id "
			select	min(office_id)
        		from	im_offices r
        		where	lower(trim(r.office_name)) = lower(trim(:office_name)) OR
        			lower(trim(r.office_path)) = lower(trim(:office_path))
    	    " -default ""]
	    if {"" == $main_office_id} {

		# First create a new main_office:
		set main_office_id [office::new \
				    -office_name	$office_name \
				    -office_path	$office_path \
				    -company_id		$company_id \
				    -office_type_id	[im_office_type_main] \
				    -office_status_id	[im_office_status_active] \
		]
	    }

	    # Now create the company with the new main_office:
	    set company_id [company::new \
				-company_id		$company_id \
				-company_name		$company_name \
				-company_path		$company_path \
				-main_office_id		$main_office_id \
				-company_type_id	$company_type_id \
				-company_status_id	$company_status_id \
			       ]
	    
	    # Write Audit Trail
	    im_audit -object_id $main_office_id -action after_create
	    im_audit -object_id $company_id -action after_create

	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=red>Error: Creating new company:<br><pre>$err_msg</pre></font>\n" }
	    continue	   
	}

    } else {
	if {$ns_write_p} { ns_write "<li>Company already exists: name='$company_name', id='$company_id'\n" }

	db_1row company_info "
                select main_office_id
                from im_companies
                where company_id = :company_id
        "
    }

    if {$ns_write_p} { ns_write "<li>Going to update the company.\n" }
    if {[catch {

	set update_office_sql "
	update im_offices set
		office_name = :office_name,
		phone = :phone,
		fax = :fax,
		address_line1 = trim(:address_line1),
		address_line2 = trim(:address_line2),
		address_city = :address_city,
		address_postal_code = :address_postal_code,
		address_country_code = :address_country_code
	where
		office_id = :main_office_id
        "
	db_dml update_offices $update_office_sql

	set update_company_sql "
  	update im_companies set
		company_path = :company_path,
		company_status_id = :company_status_id,
		company_type_id = :company_type_id,
		main_office_id = :main_office_id,
		crm_status_id = :crm_status_id,
		vat_number = :vat_number
	where
		company_id = :company_id
        "

    } err_msg]} {
	if {$ns_write_p} { ns_write "<li><font color=red>Error: Error updating company:<br><pre>$err_msg</pre></font>" }
	continue	   
    }


    # -------------------------------------------------------
    # Import DynFields   
    set company_dynfield_updates {}
    set task_dynfield_updates {}
    array unset attributes_hash
    array set attributes_hash {}
    db_foreach store_dynfiels $dynfield_sql {
	ns_log Notice "import-im_company: name=$attribute_name, otype=$object_type, table=$table_name"

	# Avoid storing attributes multipe times into the same table.
	# Sub-types can have the same attribute defined as the main type, so duplicate
	# DynField attributes are OK.
	set key "$attribute_name-$table_name"
	if {[info exists attributes_hash($key)]} {
	    ns_log Notice "import-im_company: name=$attribute_name already exists."
	    continue
	}
	set attributes_hash($key) $table_name
	lappend company_dynfield_updates "$attribute_name = :$attribute_name"
    }

    if {$ns_write_p} { ns_write "<li>Going to update im_company DynFields.\n" }
    if {"" != $company_dynfield_updates} {
	set company_update_sql "
		update im_companies set
		[join $company_dynfield_updates ",\n\t\t"]
		where company_id = :company_id
	"
	if {[catch {
	    db_dml company_dynfield_update $company_update_sql
	} err_msg]} {
	    if {$ns_write_p} { ns_write "<li><font color=brown>Warning: Error updating im_company dynfields:<br><pre>$err_msg</pre></font>" }
	}
    }

    if {$ns_write_p} { ns_write "<li>Going to write audit log.\n" }
    im_audit -object_id $company_id -action after_update

}


if {$ns_write_p} {
    ns_write "</ul>\n"
    ns_write "<p>\n"
    ns_write "<A HREF=$return_url>Return to Company Page</A>\n"
}

# ------------------------------------------------------------
# Render Report Footer

if {$ns_write_p} {
    ns_write [im_footer]
}


