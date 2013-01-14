ad_page_contract {
    @author malte.sussdorff@cognovis.de
} {
}

set return_url "/intranet"
set user_id [ad_maybe_redirect_for_registration]
set page_title "Download Resources CSV"
set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set column_headers [list]
set csv_separator ";"
# Get the first and last month
set current_month [db_string first_month "select to_char(min(item_date),'YYMM') from im_planning_items"]
set last_month [db_string last_month "select to_char(max(item_date),'YYMM') from im_planning_items"]

while {$current_month<$last_month} {
    lappend column_headers $current_month
    set current_month [db_string current_month "select to_char(to_date(:current_month,'YYMM') + interval '1 month','YYMM') from dual"]
}

# Add six more months
set i 0
while {$i<7} {
    incr i
    lappend column_headers $current_month
    set current_month [db_string current_month "select to_char(to_date(:current_month,'YYMM') + interval '1 month','YYMM') from dual"]
}

set csv_header "username;personnel_number;project_name;project_nr;company_id"
foreach col $column_headers {
    
    # Generate a header line for CSV export. Header uses the
    # non-localized text so that it's identical in all languages.
    if {"" != $csv_header} { append csv_header $csv_separator }
    append csv_header "\"[ad_quotehtml $col]\""
}

set ctr 0
set csv_body ""

# Get the username / project combinations

set user_projects [list]
db_foreach projects_info_query {select username,project_name,personnel_number,project_id,employee_id,project_nr,company_id
    from im_planning_items i, im_projects p, im_employees e, users u
    where u.user_id = i.item_project_member_id
    and p.project_id = i.item_project_phase_id
    and e.employee_id = u.user_id
    group by username,project_name,personnel_number,employee_id,project_id,project_nr,company_id
    order by username,project_name
} {
    set user_project "${employee_id}-${project_id}"
    lappend user_projects $user_project
    set csv_lines($user_project) "${username};${personnel_number};${project_name};${project_nr};${company_id}"
}

foreach user_project $user_projects {
    set ttt [split $user_project "-"]
    set employee_id [lindex $ttt 0]
    set project_id [lindex $ttt 1]
    set csv_line $csv_lines($user_project)
    
    # Try to avoid building an array
    # Loop through all the column headers and set them to ""
    foreach month $column_headers {
	set $month ""
    }
    
    # Now load all the months variables
    db_foreach months_info {select to_char(item_value/100,'9D9') as availability, to_char(item_date,'YYMM') as month 
	from im_planning_items 
	where item_project_member_id = :employee_id
	and item_project_phase_id = :project_id
    } {
	set $month $availability
    }

    # Now append the values
    foreach column_var $column_headers {
	append csv_line $csv_separator
	append csv_line "\"[im_csv_duplicate_double_quotes [set $column_var]]\""
    }

    append csv_line "\r\n"
    append csv_body $csv_line
    incr ctr
}


# !! This code only works with aolserver4.0. !!
# The older server (aolserver3.3oacs) doesn't handle
# encodings correctly.
#
set string "$csv_header\r\n$csv_body\r\n"

# TCL Encoding, application type and character set - iso8859-1 or UTF-8?
set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

if {"utf-8" == $tcl_encoding} { 
    set string_latin1 $string
} else { 
    set string_latin1 [encoding convertto $tcl_encoding $string]
}

# For some reason we have to send out a "hard" HTTP
# header. ns_return and ns_respond don't seem to convert
# the content string into the right Latin1 encoding.
# So we do this manually here...
set csv_tmp [ns_tmpnam]
set file [open $csv_tmp w]
fconfigure $file -encoding "$tcl_encoding"
puts $file $string_latin1
flush $file
close $file

set outputheaders [ns_conn outputheaders]
ns_set cput $outputheaders "Content-Disposition" "attachment; filename=resources.csv"
ns_returnfile 200 application/csv $csv_tmp
