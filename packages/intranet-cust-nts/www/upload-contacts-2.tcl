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

    set personnel_number ""
    set old_personnel_number ""
    set first_names ""
    set last_name ""
    set gender ""
    set entry_date ""
    set exit_date ""
    set profile_id 0
    set employee_status_id 0
    set availability ""
    set panf ""

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
    
    set employee_id [db_string employee "select employee_id from im_employees where personnel_number = :personnel_number" -default ""]
    
    if {"" == $employee_id} {
	set employee_id [db_string employee "select person_id from persons where 	lower(first_names) = lower(:first_names) 
			and lower(last_name) = lower(:last_name) and person_id not in (select party_id from parties where email like '%.local')" -default ""]
    }

    if {$employee_id eq ""} {
	# Find out the employee_id
	regsub -all {ä} $first_names {ae} first_names
	regsub -all {ö} $first_names {oe} first_names
	regsub -all {ü} $first_names {ue} first_names
	regsub -all {ß} $first_names {ss} first_names
	regsub -all {ä} $last_name {ae} last_name
	regsub -all {ö} $last_name {oe} last_name
	regsub -all {ü} $last_name {ue} last_name
	regsub -all {ß} $last_name {ss} last_name
	
	set employee_id [db_string employee "select person_id from persons where 	lower(first_names) = lower(:first_names) 
			and lower(last_name) = lower(:last_name) and person_id not in (select party_id from parties where email like '%.local')" -default ""]
    } else {
	db_dml update_names "update persons set first_names = :first_names, last_name = :last_name where person_id = :employee_id"
    }
    
    if {"" == $employee_id} {
	set username "${first_names}.${last_name}"
	set email "${username}@neusoft.com"
	auth::create_user -email $email -username $username -first_names $first_names -last_name $last_name 
#	set employee_id [person::new -
#	person::new -first_names $first_names -last_name $last_name -email $email
	ns_write "<li>Error: $first_names $last_name $email in $linecount is not in LDAP.<br>"
	continue
    }	

    # -------------------------------------------------------
    # Deal with the users's profile membership
    #

    # Delete the user from an profiles
    db_foreach rel_id {select object_id_one as profile_id from acs_rels where object_id_two = :employee_id and object_id_one != -2} {
	im_exec_dml delete_user "user_group_member_del ($profile_id, $employee_id)"
    }

    set rel_id [relation_add -member_state "approved" "membership_rel" "-2" $employee_id]	

    # Now add the user again
    foreach profile_id [list 459 471 469 585 473 467 36562 10739 36574 463 36568 465] {
	
	if {[exists_and_not_null $profile_id]} {
	    # Make the user a member of the group (=profile)
	    ns_log Notice "upload-contacts-2: => relation_add $profile_id $employee_id"
	    set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $employee_id]
	    db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
	    ns_write "<li>'$first_names $last_name': Added to group '$profile_id' :: $rel_id.\n"
	}
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
	resigned { set employee_status_id 452 }
	default {set employee_status_id ""}
    }

#    set employee_status_id [db_string category_id "select category_id from im_categories where category = :status" -default 0]
#    if {0 != $employee_status_id} {
	db_dml update_status "update im_employees set employee_status_id = :employee_status_id where employee_id = :employee_id"
#    }

    # Translate the weekhours
    if {"" == $week_hours} {
	set availability "100"
    } else {
	set availability [expr $week_hours / 40]
    }


    # add the note as a note of type 11512
    if {"" != $note} {
	set note [string trim $note]
	set duplicate_note_sql "
                select  count(*)
                from    im_notes
                where   object_id = :employee_id and note = :note
        "
	if {[db_string dup $duplicate_note_sql -default 0]==0} {
	    set note_id [db_exec_plsql create_note "	
		SELECT im_note__new(
			null,
			'im_note',
			now(),
			:employee_id,
			'[ad_conn peeraddr]',
			null,
			:note,
			:employee_id,
			11512,
			[im_note_status_active]
		)
        "]
	}
    }

    # Add the last change as note of type 11514
    if {"" != $change} {
	set date [string range $change 0 7]
	set note [string trim [string range $change 8 end]]
	set duplicate_note_sql "
                select  count(*)
                from    im_notes
                where   object_id = :employee_id and note = :note
        "
	if {[db_string dup $duplicate_note_sql -default 0]==0} {
	    set note_id [db_exec_plsql create_note "	
		SELECT im_note__new(
			null,
			'im_note',
			to_date(:date,'YYYYMMDD'),
			:employee_id,
			'[ad_conn peeraddr]',
			null,
			:note,
			:employee_id,
			11514,
			[im_note_status_active]
		)
        "]
	}
    }

    # define the department id
    if {"" != $level_2} {
	set department_id [db_string department "select cost_center_id from im_cost_centers where cost_center_name = :level_2" -default 525]
    } else {
	set department_id [db_string department "select cost_center_id from im_cost_centers where cost_center_name = :level_1" -default 525]	
    }

    # deal with the supervisor
    set supervisor_first [string range $supervisor 0 0]
    set supervisor_last [string range $supervisor 1 end]
    set username "${supervisor_first}.$supervisor_last"
    set supervisor_id [db_string supervisor "select user_id from users where lower(username)=lower(:username)" -default ""]

    # Make the department manager the manager for the employee
    if {"" == $supervisor_id} {
	set supervisor_id [db_string manager "select manager_id from im_cost_centers where cost_center_id = :department_id" -default ""]
    }
    if {$supervisor_id eq $employee_id} {
	set supervisor_id ""
    }

    db_dml update_employee "update im_employees set department_id = :department_id, availability = :availability, personnel_number=:personnel_number, old_personnel_number=:old_personnel_number, panf=:panf, supervisor_id = :supervisor_id where employee_id = :employee_id"
    db_dml update_person "update persons set gender=:gender where person_id = :employee_id"

    # Update the dates
    set rep_cost_ids [db_list rep_costs_exist "
	select	rc.rep_cost_id
	from	im_repeating_costs rc,
		im_costs ci
	where 	rc.rep_cost_id = ci.cost_id
		and ci.cause_object_id = :employee_id
"]


    if {$exit_date eq "" || $exit_date eq "?"} {
	set exit_date "31.12.50"
    }

    if {$entry_date eq "" || $entry_date eq "?"} {
	set entry_date "01.11.12"
    }

    if {[llength $rep_cost_ids] == 0} {
	set rep_cost_id [im_cost::new -object_type "im_repeating_cost" -cost_name $employee_id -cost_type_id [im_cost_type_employee]]
	db_dml insert_repeating_costs "
			insert into im_repeating_costs (
				rep_cost_id,
				start_date,
				end_date
			) values (
				:rep_cost_id,
				to_date(:entry_date,'DD.MM.YY'),
				to_date(:exit_date,'DD.MM.YY')
			)"
    } else {
	set rep_cost_id [lindex $rep_cost_ids 0]
	db_dml update_repeating_costs "
			update im_repeating_costs set start_date = to_date(:entry_date,'DD.MM.YY'),end_date = to_date(:exit_date,'DD.MM.YY') where rep_cost_id = :rep_cost_id"
    }
    
    db_dml update_costs "
			update im_costs set
				cause_object_id = :employee_id
			where
				cost_id = :rep_cost_id
		"
	    

    
    # add the external dienstleister

    if {$external != "" && $external != "andere"} {
	set provider_id [im_company_find_or_create -company_name $external -company_type_id 56]
	im_biz_object_add_role $employee_id $provider_id 1300
    }

}

# Remove all permission related entries in the system cache
im_permission_flush


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]
