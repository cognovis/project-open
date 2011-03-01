# /packages/intranet-trans-invoices/www/upload-prices-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    /intranet/companies/upload-prices-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into im_trans_prices
} {
    return_url
    company_id:integer
    upload_file
} 

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_costs]} {
    ad_return_complaint 1 "[_ intranet-trans-invoices.lt_You_have_insufficient_1]"
    return
}


set page_title "Upload New File/URL"
set context_bar [im_context_bar [list "/intranet/cusomers/" "Clients"] "Upload CSV"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-prices-2.tcl" -value $tmp_filename
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
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '%tmp_filename%'. 
    Please check the file permissions or price your system administrator."
    append page_body "\n$err_msg\n"
    ad_return_template
    return
}
    
set csv_files_content [exec /bin/cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set separator [im_csv_guess_separator $csv_files]
set csv_files_len [llength $csv_files]
set csv_header [lindex $csv_files 1]
set csv_headers [split $csv_header $separator]

# Check the length of the title line 
set header [string trim [lindex $csv_files 0]]
set header_csv_fields [split $header $separator]
set header_len [llength $header_csv_fields]

append page_body "Title-Length=$header_len\n"
append page_body "\n\n"

db_dml delete_old_prices "delete from im_trans_prices where company_id=:company_id"

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_fields [split $csv_line $separator]

    append page_body "Line #%i%: $csv_line\n"

    # Skip empty lines or line starting with "#"
    if {[string equal "" [string trim $csv_line]]} { continue }
    if {[string equal "#" [string range $csv_line 0 0]]} { continue }


    # Preset values, defined by CSV sheet:
    set uom ""
    set company ""
    set task_type ""
    set target_language ""
    set source_language ""
    set subject_area ""
    set file_type ""
    set valid_from ""
    set valid_through ""
    set price ""
    set min_price ""
    set currency ""
    set note ""

    # Read one line of values and write values into local variables
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
    set source_language_id ""
    set target_language_id ""
    set subject_area_id ""
    set file_type_id ""

    set errmsg ""
    if {![string equal "" $uom]} {
        set uom_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet UoM' and lower(category) = lower(:uom)" -default 0]
        if {$uom_id == 0} { append errmsg "<li>Didn't find UoM '$uom'\n" }
    }

    set company [string trim $company]
    if {![string equal "" $company]} {
	set price_company_id [db_string get_company_id "select company_id from im_companies where lower(company_path) = lower(:company)" -default 0]
        if {$price_company_id == 0} { 
	     set price_company_id [db_string get_company_id "select company_id from im_companies where lower(company_name) = lower(:company)" -default 0] 
	}
        if {$price_company_id == 0} { append errmsg "<li>Didn't find Company '$company'\n" }
        if {$price_company_id != $company_id} { 
	    append errmsg "<li>Uploading prices for the wrong company ('$price_company_id' instead of '$company_id')" 
	}
    }

    if {![string equal "" $task_type]} {
        set task_type_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Project Type' and lower(category) = lower(trim(:task_type))"  -default 0]
        if {$task_type_id == 0} { append errmsg "<li>Didn't find Task Type '$task_type'\n" }
    }

    set source_language_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Translation Language' and lower(category) = lower(trim(:source_language))"  -default ""]
    if {$source_language_id == "" && $source_language != ""} { 
        append errmsg "<li>Didn't find Source Language '$source_language'\n" 
    }

    set target_language_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Translation Language' and lower(category) = lower(trim(:target_language))"  -default ""]
    if {$target_language_id == "" && $target_language != ""} { 
        append errmsg "<li>Didn't find Target Language '$target_language'\n" 
    }


    set subject_area_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Translation Subject Area' and lower(category) = lower(trim(:subject_area))"  -default ""]
    if {$subject_area_id == "" && $subject_area != ""} { 
        append errmsg "<li>Didn't find Subject Area '$subject_area'\n" 
    }


    set file_type_id [db_string get_uom_id "select category_id from im_categories where category_type='Intranet Translation File Type' and lower(category) = lower(trim(:file_type))"  -default ""]
    if {$file_type_id == "" && $file_type != ""} { 
        append errmsg "<li>Didn't find File Type '$file_type'\n" 
    }



    # It doesn't matter whether prices are given in European "," or American "." decimals
    regsub {,} $price {.} price

#    append page_body "uom_id=$uom_id\n"
#    append page_body "company_id=$company_id\n"
#    append page_body "task_type_id=$task_type_id\n"
#    append page_body "source_language_id=$source_language_id\n"
#    append page_body "target_language_id=$target_language_id\n"
#    append page_body "subject_area_id=$subject_area_id\n"
#    append page_body "file_type_id=$file_type_id\n"
#    append page_body "valid_from=$valid_from\n"
#    append page_body "valid_through=$valid_through\n"
#    append page_body "price=$price\n"
#    append page_body "currency=$currency\n"

    set price_id [db_nextval "im_trans_prices_seq"]

    set insert_price_sql "INSERT INTO im_trans_prices (
	price_id, uom_id, company_id, task_type_id,
	target_language_id, source_language_id, subject_area_id,
	file_type_id,
       valid_from, valid_through, currency, price, min_price, note
    ) VALUES (
	:price_id, :uom_id, :company_id, :task_type_id,
	:target_language_id, :source_language_id, :subject_area_id,
	:file_type_id,
	:valid_from, :valid_through, :currency, :price, :min_price, :note
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

append page_body "\n<A HREF=$return_url>Return to Project Page</A>\n"

ad_return_template
