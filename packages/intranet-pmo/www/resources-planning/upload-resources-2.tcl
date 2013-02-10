# /packages/intranet-core/www/companies/upload-contacts-2.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------


ad_page_contract {
    /intranet/companies/upload-ressources-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into "users" and
    "acs_rels".

    @author various@arsdigita.com
    @author malte.sussdorff@cognovis.de

    @param transformation_key Determins a number of additional fields 
	   to import
    @param create_dummy_email Set this for example to "@nowhere.com" 
	   in order to create dummy emails for users without email.

} {
    return_url
    upload_file
    { transformation_key "" }
    { create_dummy_email "" }
} 


# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Contacts CSV"
set page_body ""
set context_bar [im_context_bar $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


# ---------------------------------------------------------------
# Get the uploaded file
# ---------------------------------------------------------------

# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-contacts-2.tcl" -value $tmp_filename
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match company_filename] {
    # couldn't find a match
    set company_filename $upload_file
}

if {[regexp {\.\.} $company_filename]} {
    ad_return_complaint 1 "Filename contains forbidden characters"
}

if {![file readable $tmp_filename]} {
    ad_return_complaint 1 "Unable to read the file '$tmp_filename'. 
Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}


# ---------------------------------------------------------------
# Extract CSV contents
# ---------------------------------------------------------------

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]

set separator [im_csv_guess_separator $csv_files]

# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
set csv_header_len [llength $csv_header_fields]
set values_list_of_lists [im_csv_get_values $csv_files_content $separator]


# ---------------------------------------------------------------
# Render Page Header
# ---------------------------------------------------------------

# This page is a "streaming page" without .adp template,
# because this page can become very, very long and take
# quite some time.

ad_return_top_of_page "
        [im_header]
        [im_navbar]
"


# ---------------------------------------------------------------
# Start parsing the CSV
# ---------------------------------------------------------------

set linecount 0
foreach csv_line_fields $values_list_of_lists {
    incr linecount
    
    # -------------------------------------------------------
    # Extract variables from the CSV file
    # Loop through all columns of the CSV file and set 
    # local variables according to the column header (1st row).

    set var_name_list [list]
    set pretty_field_string ""
    set pretty_field_header ""
    set pretty_field_body ""

    set first_names ""
    set last_name ""
    set personnel_number ""
    set profile_id 0
    set employee_status_id 0
    set availability ""

    for {set j 0} {$j < $csv_header_len} {incr j} {

	set var_name [string trim [lindex $csv_header_fields $j]]
	set var_name [string tolower $var_name]
	set var_name [string map -nocase {" " "_" "\"" "" "'" "" "/" "_" "-" "_"} $var_name]
	set var_name [im_mangle_unicode_accents $var_name]

	# Deal with German Outlook exports
	set var_name [im_upload_cvs_translate_varname $var_name]

	lappend var_name_list $var_name
	
	set var_value [string trim [lindex $csv_line_fields $j]]
	set var_value [string map -nocase {"\"" "" "\{" "(" "\}" ")" "\[" "(" "\]" ")"} $var_value]
	if {[string equal "NULL" $var_value]} { set var_value ""}
	append pretty_field_header "<td>$var_name</td>\n"
	append pretty_field_body "<td>$var_value</td>\n"

#	append pretty_field_string "$var_name\t\t$var_value\n"
#	ns_log notice "upload-contacts: [lindex $csv_header_fields $j] => $var_name => $var_value"	

	set cmd "set $var_name \"$var_value\""
#	ns_log Notice "upload-contacts-2: cmd=$cmd"
	set result [eval $cmd]
    }

    # Get the first and last month
    set current_month [db_string first_month "select to_char(min(item_date),'YYMM') from im_planning_items"]
    set last_month [db_string last_month "select to_char(max(item_date),'YYMM') from im_planning_items"]
    set months [list]
    while {$current_month<$last_month} {
	lappend months $current_month
	set current_month [db_string current_month "select to_char(to_date(:current_month,'YYMM') + interval '1 month','YYMM') from dual"]
    }
    
    # Add six more months
    set i 0
    while {$i<7} {
	incr i
	lappend months $current_month
	set current_month [db_string current_month "select to_char(to_date(:current_month,'YYMM') + interval '1 month','YYMM') from dual"]
    }

    set employee_id [db_string employee "select employee_id from im_employees where personnel_number = :personnel_number" -default ""]

    set project_id ""
        
    if {[exists_and_not_null project_nr] && [exists_and_not_null company_id]} {
	set project_id [db_string project "select project_id from im_projects where project_nr = :project_nr and company_id = :company_id" -default ""]
    }

    # find the employee and the project
    if {"" != $employee_id && "" != $project_id} {
	set current_availability 0
	set avail ""
	foreach month $months {
	    if {![info exists $month]} {
		ns_write "<li>ERROR $employee_id :: $personnel_number ---- $project_id :: $month</li>"		    
		continue
	    }
	    set start_date "01$month"
	    set availability [set $month]
	    
	    # we need to find out if we update or insert
	    set planning_item_id [db_string planning_item "select item_id from im_planning_items 
            	       		  where item_date = to_date(:start_date,'DDYYMM')
                	          and item_project_phase_id = :project_id
        			  and item_project_member_id = :employee_id" -default ""]
	    
	    if {"" != $availability} {
		# Convert to float numbers
		regsub -all "," $availability "." availability
		
		# Make sure we store percentages
		set availability [ expr $availability * 100 ]
		
		# Find out if we need to create the relationship
		set current_date "01"
		append current_date [db_string date "select to_char(now(),'YYMM') from dual"]
		
		if {$current_date == $start_date} {
		    set current_availability $availability
		}
		
		# Make this an effort
		if {"" == $planning_item_id} {
		    set planning_item_id [planning_item::new \
					      -item_object_id $project_id \
					      -item_project_phase_id $project_id \
					      -item_project_member_id $employee_id \
					      -item_type_id 73103 \
					      -item_cost_type_id 3718 \
					      -item_date [db_string date "select to_char(to_date(:start_date,'DDYYMM'),'YYYY-MM-DD')"] \
					      -item_value $availability]
		} else {
		    db_dml update_planning_item "update im_planning_items set item_value = :availability, item_type_id = 73103 where item_id = :planning_item_id "
		}
		
	    } else {
		if {"" != $planning_item_id} {
		    db_dml delete_planning_item "delete from im_planning_items where item_id = :planning_item_id"
		    db_dml delete_planning_item "delete from acs_objects where object_id = :planning_item_id"
		}
	    }
	}
	
	# Create the rel
	if {$current_availability > 0} {
	    # Find out if the relationship already exists
	    set rel_id [db_string select_rel "select rel_id from acs_rels where object_id_one = :project_id and object_id_two = :employee_id" -default ""]
	    if {"" == $rel_id} {
		# Create the relationship for this month
		set rel_id [im_biz_object_add_role -percentage $current_availability $employee_id $project_id 1300]
	    } else {
		# Update the relationship
		db_dml update_availability "update im_biz_object_members set percentage = :current_availability where rel_id = :rel_id"
	    }
	} else {
	    # Remove the relationship
	    set rel_id [db_string select_rel "select rel_id from acs_rels where object_id_one = :project_id and object_id_two = :employee_id" -default ""]
	    if {$rel_id ne ""} {
		ns_log Notice "This rel $rel_id for $project_id :: $personnel_number should be removed"
	    }
	}
    } else {
	ds_comment "Can't add personnel $personnel_number for Employee $employee_id in Project $project_id :: $project_nr"
    }
}


# ------------------------------------------------------------
# Render Report Footer
ns_write "We are finished. You can <a href=\"index\">Return</a> now."
ns_write [im_footer]
