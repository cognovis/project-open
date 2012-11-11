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
    /intranet/companies/upload-contacts-2.tcl
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
	ns_log Notice "upload-contacts-2: cmd=$cmd"
	set result [eval $cmd]
    }

    switch $customer {
	HAD {set company_id [db_string company "select company_id from im_companies where company_path = 'had'"]}
	NT {set company_id [db_string company "select company_id from im_companies where company_path = 'nt'"]}
	default {set company_id [db_string company "select company_id from im_companies where company_path = 'internal'"]} 
    }

    switch $project_category {
	"HAD T&M" {set project_type_id 2511}
	"Guest" {set project_type_id 2512}
	"NTS Overhead" {set project_type_id 2513}
	"HAD FPP" {set project_type_id 2514}
	"NTS FPP" {set project_type_id 2515}
	default {set project_type_id 86}
    }

    # create the program
    set program_id [db_string program_id "select project_id from im_projects where project_name = :program" -default ""]
    if {"" == $program_id && "" != $program} {
	set project_path [string tolower [string trim $program]]
	set project_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $project_path]

        set program_id [project::new \
                            -project_name $program \
                            -project_nr $program \
                            -project_path $project_path \
                            -company_id $company_id \
                            -parent_id "" \
                            -project_type_id 2501 \
                            -project_status_id 76\
                           ]
	db_dml project_info "update im_projects set sow = :sow, gs_int = :gs_int, gs_ext=:gs_ext, start_date = to_date('2012-01-01','YYYY-MM-DD'), end_date = to_date('2013-06-30','YYYY-MM-DD') where project_id = :program_id"
    }
    
    # only create PSP and project_name hierarchy for HAD
    if {$customer == "HAD" && $program_id ne ""} {

	# create the PSP
	set psp_id [db_string psp_id "select project_id from im_projects where project_name = :psp" -default ""]
	if {"" == $psp_id && "" != $psp} {
	    set project_path [string tolower [string trim $psp]]
	    set project_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $project_path]
	    
	    set psp_id [project::new \
                            -project_name $psp \
                            -project_nr "psp_$psp" \
                            -project_path $project_path \
                            -company_id $company_id \
                            -parent_id $program_id \
                            -project_type_id 2501 \
                            -project_status_id 76\
                           ]
	    db_dml project_info "update im_projects set sow = :sow, gs_int = :gs_int, gs_ext=:gs_ext, start_date = to_date('2012-01-01','YYYY-MM-DD'), end_date = to_date('2013-06-30','YYYY-MM-DD') where project_id = :psp_id"
    }
	
	
	# create the main_project
	set main_project_id [db_string main_project_id "select project_id from im_projects where project_name = :project_name" -default ""]
	if {"" == $main_project_id && "" != $project_name} {
	    set project_path [string tolower [string trim $project_name]]
	    set project_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $project_path]
	    
	    set main_project_id [project::new \
				     -project_name $project_name \
				     -project_nr $project_name \
				     -project_path $project_path \
				     -company_id $company_id \
				     -parent_id $psp_id \
				     -project_type_id 2501 \
				     -project_status_id 76\
				    ]
	    db_dml project_info "update im_projects set sow = :sow, gs_int = :gs_int, gs_ext=:gs_ext, start_date = to_date('2012-01-01','YYYY-MM-DD'), end_date = to_date('2013-06-30','YYYY-MM-DD') where project_id = :main_project_id"
	}
	
	# Create the project
	set project_id [db_string project_id "select project_id from im_projects where project_name = :project_ref" -default ""]
	if {"" == $project_id && "" != $project_ref} {
	    set project_path [string tolower [string trim $project_ref]]
	    set project_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $project_path]
	    set project_id [project::new \
				-project_name $project_ref \
				-project_nr $project_code \
				-project_path $project_path \
				-company_id $company_id \
				-parent_id $main_project_id \
				-project_type_id $project_type_id \
				-project_status_id 76\
			       ]
	    db_dml project_info "update im_projects set sow = :sow, gs_int = :gs_int, gs_ext=:gs_ext, start_date = to_date('2012-01-01','YYYY-MM-DD'), end_date = to_date('2013-06-30','YYYY-MM-DD') where project_id = :project_id"
	}
    } else {
	# Create the project
	set project_id [db_string project_id "select project_id from im_projects where project_name = :project_ref" -default ""]
	if {"" == $project_id && "" != $project_ref} {
	    set project_path [string tolower [string trim $project_ref]]
	    set project_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $project_path]
	    set project_id [project::new \
				-project_name $project_ref \
				-project_nr $project_code \
				-project_path $project_path \
				-company_id $company_id \
				-parent_id $program_id \
				-project_type_id $project_type_id \
				-project_status_id 76\
			       ]
	    db_dml project_info "update im_projects set sow = :sow, gs_int = :gs_int, gs_ext=:gs_ext, start_date = to_date('2012-01-01','YYYY-MM-DD'), end_date = to_date('2013-06-30','YYYY-MM-DD') where project_id = :project_id"
	}
    }
    ns_write "<li>'$program :: $psp :: $project_name'\n $project_id</li>"
}


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]
