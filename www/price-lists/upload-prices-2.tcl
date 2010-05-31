# /packages/intranet-timesheet2-invoices/www/upload-prices-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    /intranet/companies/upload-prices-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into im_timesheet_prices
} {
    return_url
    company_id:integer
    upload_file
} 

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "<#_ Upload New File/URL#>"
set page_body "<PRE>\n<A HREF=$return_url><#_ Return to Company Page#></A>\n"
set context_bar [im_context_bar [list "/intranet/cusomers/" "<#_ Clients#>"] "<#_ Upload CSV#>"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-prices-2.tcl" -value $tmp_filename
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "<#_ Your file is larger than the maximum permissible upload size#>:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match company_filename] {
    # couldn't find a match
    set company_filename $upload_file
}

if {[regexp {\.\.} $company_filename]} {
    set error "<#_ Filename contains forbidden characters#>"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    set err_msg "<#_ Unable to read the file '%tmp_filename%'.#> 
<#_ Please check the file permissions or price your system administrator.#>"
    append page_body "\n$err_msg\n"
    ad_return_template
    return
}
    
set csv_files_content [exec /bin/cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]
set csv_header [lindex $csv_files 1]
set csv_headers [split $csv_header ";"]

# Check the length of the title line 
set header [string trim [lindex $csv_files 0]]
set header_csv_fields [split $header ";"]
set header_len [llength $header_csv_fields]

append page_body "Title-Length=$header_len\n"
append page_body "\n\n"

db_dml delete_old_prices "delete from im_timesheet_prices where company_id=:company_id"

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_fields [split $csv_line ";"]

    append page_body "<#_ Line #%i%#>: $csv_line\n"

    # Skip empty lines or line starting with "#"
    if {[string equal "" [string trim $csv_line]]} { continue }
    if {[string equal "#" [string range $csv_line 0 0]]} { continue }


    # Preset values, defined by CSV sheet:
    set uom ""
    set company ""
    set task_type ""
    set material ""
    set valid_from ""
    set valid_through ""
    set price ""
    set currency ""

    for {set j 0} {$j < $header_len} {incr j} {
	set var_name [lindex $header_csv_fields $j]
	set var_value [lindex $csv_fields $j]
	set cmd "set $var_name "
	append cmd "\""
	append cmd $var_value
	append cmd "\""
	ns_log Notice "cmd=$cmd"

	if { [catch {	
	    set result [eval $cmd]
	} err_msg] } {
	    append page_body \n<font color=red>$err_msg</font>\n";
        }
#	append page_body "set $var_name '$var_value' : $result\n"
    }

    set uom_id ""
    set task_type_id ""
    set material_id ""

    set errmsg ""
    if {![string equal "" $uom]} {
        set uom_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet UoM' and category=:uom" -default 0]
        if {$uom_id == 0} { append errmsg "<li>Didn't find UoM '$uom'\n" }
    }

    if {![string equal "" $company]} {
         set price_company_id [db_string get_company_id "select company_id from im_companies where company_path = :company" -default 0]
         if {$price_company_id == 0} { append errmsg "<li>Didn't find Company '$company'\n" }
         if {$price_company_id != $company_id} { append errmsg "<li>Uploading prices for the wrong company ('$price_company_id' instead of '$company_id')" }
    }

    if {![string equal "" $task_type]} {
        set task_type_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Project Type' and category=:task_type"  -default 0]
        if {$task_type_id == 0} { append errmsg "<li>Didn't find Task Type '$task_type'\n" }
    }

    set material_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Translation Subject Area' and category=:material"  -default ""]

    # It doesn't matter whether prices are given in European "," or American "." decimals
    regsub {,} $price {.} price

#    append page_body "\n"
#    append page_body "uom_id=$uom_id\n"
#    append page_body "company_id=$company_id\n"
#    append page_body "task_type_id=$task_type_id\n"
#    append page_body "material_id=$material_id\n"
#    append page_body "valid_from=$valid_from\n"
#    append page_body "valid_through=$valid_through\n"
#    append page_body "price=$price\n"
#    append page_body "currency=$currency\n"

    set insert_price_sql "INSERT INTO im_timesheet_prices (
       price_id, uom_id, company_id, task_type_id, material_id,
       valid_from, valid_through, currency, price
    ) VALUES (
       nextval('im_timesheet_prices_seq'), :uom_id, :company_id, :task_type_id, :material_id,
       :valid_from, :valid_through, :currency, :price
    )"

    if {[string equal "" $errmsg]} {
        if { [catch {
             db_dml insert_price $insert_price_sql
        } err_msg] } {
	    append page_body \n<font color=red>$err_msg</font>\n";
        }
    } else {
	append page_body "<font color=red>$errmsg</font>"
    }
}

append page_body "\n<A HREF=$return_url><#_ Return to Project Page#></A>\n"

ad_return_template
