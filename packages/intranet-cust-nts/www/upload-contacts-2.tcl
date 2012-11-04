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
    @author frank.bergmann@project-open.com

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

    # We only import NTS employees
    if {"NTS" != $level_0} {
	continue
    }

    if {"" == $first_names} {
	ns_write "<li>Error: We have found an empty 'First Name' in line $linecount.<br>
        Error: We can not add users with an empty first name, Please correct the CSV file.
        <br><pre>$pretty_field_string</pre>"
	continue
    }

    if {"" == $last_name} {
	ns_write "<li>Error: We have found an empty 'Last Name' in line $linecount.<br>
        We can not add users with an empty last name. Please correct the CSV file.<br>
        <pre>$pretty_field_string</pre>"
	continue
    }

    # Find out the employee_id
    set employee_id [db_string employee "select person_id from persons where 	lower(first_names) = lower(:first_names) 
			and lower(last_name) = lower(:last_name) and person_id not in (select party_id from parties where email like '%.local')" -default ""]

    if {"" == $employee_id} {
	ns_write "<li>Error: $first_names $last_name in $linecount is not in LDAP.<br>"
	continue
    }	

    # -------------------------------------------------------
    # Deal with the users's profile membership
    #

    set intern_profile_id [db_string profile "select profile_id from im_profiles where profile_gif = 'intern'"]
    set student_profile_id [db_string profile "select profile_id from im_profiles where profile_gif = 'student'"]
    switch $profile {
	"MA" {set profile_id 463}
	"Praktikum" {set profile_id $intern_profile_id}
	"ext." {set profile_id 465}
	"WS" {set profile_id $student_profile_id}
    }

    ds_comment "$profile :: $profile_id"

    if {0 != $profile_id} {
        # Make the user a member of the group (=profile)
        ns_log Notice "upload-contacts-2: => relation_add $profile_id $employee_id"
        set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $employee_id]
        db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
        ns_write "<li>'$first_names $last_name': Added to group '$profile_id'.\n"
    } else {
        ns_write "<li>'$first_names $last_name': Not adding the user to any group.\n"
    }

    ns_write "<li>
	'$first_names $last_name': Updating user ...<br>
    "  

    # Add a im_employees record to the user since the 3.0 PostgreSQL
    # port, because we have dropped the outer join with it...
    # Simply add the record to all users, even it they are not employees...
    set employee_found [db_string employee_found "select count(*) from im_employees where employee_id = :employee_id"]
    if {!$employee_found} {
	db_dml add_im_employees "insert into im_employees (employee_id) values (:employee_id)"
    }

    # Translate the employee_status_id
    switch $status {
	active { set employee_status_id 454 }
	inactive { set employee_status_id 455 }
	open { set employee_status_id 450 }
	absent { set employee_status_id 453 }
    }

    set employee_status_id [db_string category_id "select category_id from im_categories where category = :status" -default 0]
    if {0 != $employee_status_id} {
	db_dml update_status "update im_employees set employee_status_id = :employee_status_id where employee_id = :employee_id"
    }

    # Translate the weekhours
    if {"" == $week_hours} {
	set availability "100"
    } else {
	set availability [expr $week_hours / 40]
    }

    # We might have to add the cost_center later
    # Add the department now :-)
    if { "" != $level_1 } { 
	set parent_department_id [db_string department "select cost_center_id from im_cost_centers where cost_center_label = :level_1 and parent_id = 32965" -default ""]
	if {"" == $parent_department_id} {
	    # Create the parent_depar	 tment_id
	    set parent_department_id [db_string cost_center_insert "SELECT im_cost_center__new (
		null,			-- co	st_center_id
		'im_cost_center',	-- objec	t_type
		now(),			-- creation_date	
		null,			-- creation_user		
		null,			-- creation_ip			
		null,			-- context_id			
		
		:level_1,
		:level_1,
		:cost_center,
		3001,
		3101,
		32965,
		null,
		'f',
		null,
		null
	);"]
	
	    db_dml update_context "	update acs_objects set 
		context_id = 32965
		where	object_id = :parent_department_id;"
	}
	
	if {"" != $level_2} {
	    set code "$level_1 - $level_2"
	    set department_id [db_string department "select cost_center_id from im_cost_centers where cost_center_label = :code" -default ""]
	    if {"" == $department_id} {
		# We need to create the department
		ns_log Notice "$code"
		set department_id [db_string cost_center_insert "	SELECT im_cost_center__new (
		null,			-- cost_center_id
		'im_cost_center',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id

		:level_2,
		:code,
		:cost_center,
		3001,
		3101,
		:parent_department_id,
		null,
		't',
		null,
		null
	);"]
		
		db_dml update_context "	update acs_objects set 
				context_id = :parent_department_id
				where	object_id = :department_id;"

	    }
	}
    }
    
    db_dml update_employee "update im_employees set department_id = :department_id, availability = :availability, personnel_number=:personnel_number where employee_id = :employee_id"

}


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]
