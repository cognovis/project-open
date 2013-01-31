# /packages/intranet-hr/www/upload-vacationdata-2.tcl
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
    Read a .csv-file and inserts the data into im_employee_information.

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    upload_file
} 

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Vacation Data CSV"
set page_body ""
set context_bar [im_context_bar $page_title]

# Check if user is ADMIN or HR Manager
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p && ![im_profile::member_p -profile_id [im_hr_group_id] -user_id $user_id]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ---------------------------------------------------------------
# Get the uploaded file
# ---------------------------------------------------------------

# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-vacationdata-2" -value $tmp_filename

if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match filename] {
    # couldn't find a match
    set filename $upload_file
}

if {[regexp {\.\.} $filename]} {
    ad_return_complaint 1 "Filename contains unvalid characters"
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
# Perform some validation  
# ---------------------------------------------------------------

if { 7 != $csv_header_len } {
    ad_return_complaint 1 "Please check number of columns. Import routine expects the following columns:\n
	Id \n
	Name \n
	Vacation Days taken last year \n
	Vacation Days per year (current) \n
	Vacation Balance (current) \n
	Vacation Days per year (This year) \n
	Vacation Balance (This year) \n

    We only found $csv_header_len columns in the file you just uploaded.
    "
    ad_script_abort
}

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

set protocol_txt "Import Protocol:<br>" 

set linecount 0

foreach csv_line_fields $values_list_of_lists {

	incr linecount
    
	set user_id [string trim [lindex $csv_line_fields 0]]
	set vacation_balance [format %0.2f [string map {, .} [lindex $csv_line_fields 5]]]
	set vacation_days_per_year [format %0.2f [string map {, .} [lindex $csv_line_fields 6]]]

	# Check for numeric values 
	if { ![string is double -strict $vacation_balance] || ![string is double -strict $vacation_days_per_year] } {
		ad_return_complaint 1 "Found non-numeric value updating user: [lindex $csv_line_fields 1]: $vacation_balance/$vacation_days_per_year"
	}

	# Check if user exists
	if { 0 == [db_string check_email_exists "select count(*) from parties where party_id=:user_id" -default 0] } {
		ad_return_complaint 1 "Did not find user [string trim [lindex $csv_line_fields 1]] in database"
    	}

	db_1row get_current_vacation_balance_and_days "
                select
                        vacation_balance as vacation_balance_old,
                        vacation_days_per_year as vacation_days_per_year_old
                from
                        im_employees
                where
                        employee_id = :user_id
    	"
	
	# -------------------------------------------------------
	# Employee information 
	#

	if {[catch {
       		db_dml employee_information "
		        update im_employees set
       		        vacation_balance = :vacation_balance, 
			vacation_days_per_year = :vacation_days_per_year
	            where
       		        employee_id = :user_id
        "
    	} errmsg]} {
       		ns_write "<li>Error updating user - employee information \\#$user_id:<br><pre>$errmsg</pre>Please correct the problem and try again</li>"
    	}

    	append protocol_txt "Updated user: <a href='/intranet/users/view?user_id=$user_id'>[string trim [lindex $csv_line_fields 1]]</a>; Vacation Balance was: $vacation_balance_old; Vacation Balance is: $vacation_balance; "
    	append protocol_txt "Vacation days per year was: $vacation_days_per_year_old; Vacation days per year is: $vacation_days_per_year\<br>"
}

# ------------------------------------------------------------
# Render Report Footer
ns_write $protocol_txt
ns_write [im_footer]
