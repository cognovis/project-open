# /packages/intranet-reporting/www/timesheet-invoice-hours.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
    @param truncate_note_length Truncate (ellipsis) the note field
           to the given number of characters. 0 indicates no
           truncation.
} {
	include_task:multiple
    { truncate_note_length 4000}
    { project_id:integer 0}
    { task_id:integer 0}
    { user_id:integer 0}
    { printer_friendly_p:integer 1}
    { company_id:integer 0}
    { order_by "Project nr" }
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
# Uses the same label as the timesheet report.
set menu_label "reporting-timesheet-customer-project"

set current_user_id [ad_maybe_redirect_for_registration]

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# Has the current user the right to edit all timesheet information?
set edit_timesheet_p [im_permission $current_user_id "edit_hours_all"]


# ------------------------------------------------------------
# Defaults

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"


# ------------------------------------------------------------
# Constants

set date_format "YYYY-MM-DD"
set number_format "999,999.99"

# ------------------------------------------------------------

set undefined_l10n [lang::message::lookup "" intranet-reporting.undefined "&lt;undefined&gt;"]
set grand_total_l10n [lang::message::lookup "" intranet-reporting.Grand_Total "Grand Total"]
set customer_l10n [lang::message::lookup "" intranet-core.Customer "Customer"]
set project_l10n [lang::message::lookup "" intranet-core.Project "Project"]
set project_number_l10n [lang::message::lookup "" intranet-core.Project_Number "Project Number"]
set customer_po_l10n [lang::message::lookup "" intranet-reporting.Customer_PO "Customer PO"]
set date_signature_l10n [lang::message::lookup "" intranet-reporting.Date_Signature "&nbsp;&nbsp;Date, Signature"]


# ------------------------------------------------------------

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


set page_title [lang::message::lookup "" intranet-reporting.Invoice_details "Details for Project %project_id%"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set hours_url "/intranet-timesheet2/hours/one"
set this_url [export_vars -base "/intranet-reporting/timesheet-customer-project" {level_of_detail project_id task_id company_id user_id} ]


# ------------------------------------------------------------
# set "order by" 
#

if {$order_by != ""} {
    if { $order_by == "task_status" } {
                        set order_by_clause "p.project_id, task_status ASC, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $order_by == "t.task_name" } {
                        set order_by_clause "p.project_id, task_name ASC, type_name ASC, target_language ASC"
    } elseif { $order_by == "t.task_units" } {
                        set order_by_clause "p.project_id, t.task_units, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $order_by == "t.billable_units" } {
                        set order_by_clause "p.project_id, t.billable_units, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $order_by == "type_name" } {
                        set order_by_clause "p.project_id, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $order_by == "t.task_uom_id" } {
                        set order_by_clause "p.project_id, uom_name, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $order_by == "target_language" } {
                        set order_by_clause "p.project_id, target_language ASC, type_name ASC, task_name ASC"
    } else {
                        set order_by_clause "p.project_id, task_name ASC, type_name, target_language"
    }
} else {
            set order_by_clause "p.project_id"
}


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#


# Build the list of selected tasks ready for invoicing
set in_clause_list [list]
foreach selected_task $include_task {
    lappend in_clause_list $selected_task
}
set tasks_where_clause "task_id in ([join $in_clause_list ","])"

# ------------------------------------------------------------
# SQL 
#

set sql "
        select
                t.task_id,
                t.task_units,
                t.task_name,
                t.billable_units,
                t.task_uom_id,
                t.task_type_id,
                t.project_id,
		t.match_x, 
		t.match_rep, 
		t.match100, 
		t.match95,
		t.match85,
		t.match75,
		t.match50,
		t.match0,
		(t.match50 + t.match75 +  t.match85 + t.match95) as int_repetitions, 
                im_category_from_id(t.task_uom_id) as uom_name,
                im_category_from_id(t.task_type_id) as type_name,
                im_category_from_id(t.task_status_id) as task_status,
		t.target_language_id,
		t.source_language_id,
                im_category_from_id(t.target_language_id) as target_language,
                im_category_from_id(t.source_language_id) as source_language,
                p.project_name,
                p.project_path,
                p.project_path as project_short_name
        from
                im_trans_tasks t,
                im_projects p
        where
                $tasks_where_clause
                and t.project_id = p.project_id
        order by
                $order_by_clause
"


append table_header_html "<tr>\n<td class='rowtitle'></td>\n"


# ------------------------------------------------------------
# table header
#


set table_header_html "
	<table border='1' cellpadding='5' cellspacing='5'>
	<theader>
	<tr style='background-color:\#EFEFEF'>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Document/<br>Description" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Unit" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Result<br>Analysis" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "TM Rebate" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Wordcount" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Price/Unit" ]</td>
	<td>[lang::message::lookup "" intranet-core.doc_descr "Total" ]</td>
	</tr>
	</theader>
"


# ------------------------------------------------------------
# table body
#


set old_project_id 0
set task_table_rows ""
set ctr 0
set colspan 7

array set trados_array [im_trans_trados_matrix $company_id]

# 100 	0.3000 
# 95 	0.7000 
# 85 	0.7000 
# 75 	0.7000 
# 50 	1.0000 
# 0 	1.0000 
# x 	0.0000 
# rep 	0.3000 
# object 	0
# type 	internal 


db_foreach select_tasks $sql {

	set fuzzie_result 0 
	set fuzzie_no_discount 0 
      	set fuzzie_weight 0

        if { 1.0 != [expr $trados_array(50)] && 0 != [expr $trados_array(50) ] } {
            set fuzzie_result [expr $match50 + $fuzzie_result]
	    set fuzzie_weight [expr $fuzzie_weight + ($match50 * $trados_array(50)) ]
        } else {
            set fuzzie_no_discount [expr $match50 + $fuzzie_no_discount]
        }
        if { 1.0 != [expr $trados_array(75)] && 0 != [expr $trados_array(75) ] } {
            set fuzzie_result [expr $match75 + $fuzzie_result]
            set fuzzie_weight [expr $fuzzie_weight + ($match75 * $trados_array(75)) ]
        } else {
            set fuzzie_no_discount [expr $match75 + $fuzzie_no_discount]
        }
	if { 1.0 != [expr $trados_array(85)] && 0 != [expr $trados_array(85) ] } {
	    set fuzzie_result [expr $match85 + $fuzzie_result]
            set fuzzie_weight [expr $fuzzie_weight + ($match85 * $trados_array(85)) ]
	} else {
	    set fuzzie_no_discount [expr $match85 + $fuzzie_no_discount]
	}
	if { 1.0 != [expr $trados_array(95)] && 0 != [expr $trados_array(95) ] } {
	    set fuzzie_result [expr ($match95 + $fuzzie_result)]
            set fuzzie_weight [expr $fuzzie_weight + ($match95 * $trados_array(95)) ]
	} else {
	    set fuzzie_no_discount [expr $match95 + $fuzzie_no_discount]
	}	
       
        set match0 [expr $match0 + $fuzzie_no_discount ]
	set fuzzie_wordcount [expr ($match50 * $trados_array(50)) + ($match75 * $trados_array(75)) + ($match85 * $trados_array(85)) + ($match95 * $trados_array(95))]
	if { 0 != [expr $fuzzie_result] } {
	    set fuzzie_weight_sum [expr $fuzzie_weight / $fuzzie_result * 100 ]
	} else {
            set fuzzie_weight_sum $fuzzie_weight
	}
	append fuzzie_weight_sum " %"
	    
    # insert intermediate headers for every project
    if {$old_project_id != $project_id} {
        append task_table_rows "
                <tr><td colspan=$colspan>&nbsp;</td></tr>
                <tr>
                  <td class=rowtitle colspan=$colspan><a href=/intranet/projects/view?project_id=$project_id>$project_short_name</a> - $project_name:  $source_language -> $target_language </td>
                </tr>\n"
        set old_project_id $project_id
	set price [db_string price_single_word "select price from im_trans_prices where company_id = $company_id and source_language_id = $source_language_id and target_language_id=$target_language_id and uom_id=324" -default 0]
    }

    append task_table_rows "
        <tr $bgcolor([expr $ctr % 2])>
          <td align=left colspan='7'>$task_name</td></td>
        </tr>"

    # title
    append task_table_rows "
        <tr style='background-color:\#EFEFEF'>
          <td align=left></td>
          <td align=right>Unit</td>
          <td align=left>Result Analysis</td>
          <td align=left>TM Rebate</td>
          <td align=left>Wordcount</td>
          <td>Price/Unit</td>
          <td>Total</td>
        </tr>
	"

    # New words
    append task_table_rows "
        <input type=hidden name=im_trans_task value=$task_id>
        <tr $bgcolor([expr $ctr % 2])>
          <td align=left></td>
          <td align=right>[lang::message::lookup "" intranet-core.doc_descr "New Words" ]</td>
          <td align=right>$match0</td>
          <td align=right>[expr $trados_array(0) * 100 ]%</td>
          <td align=right>[expr ($trados_array(0) * $match0)]</td>
          <td>$price</td>
          <td>[expr $price * ($trados_array(0) * $match0)]</td>
        </tr>"

    # Fuzzies
    append task_table_rows "
        <input type=hidden name=im_trans_task value=$task_id>
        <tr $bgcolor([expr $ctr % 2])>
          <td align=left></td>
          <td align=right>[lang::message::lookup "" intranet-core.doc_descr "Fuzzies" ]</td>
          <td align=right>$fuzzie_result</td>
          <td align=right>$fuzzie_weight_sum</td>
          <td align=right>$fuzzie_wordcount</td>
          <td>$price</td>
          <td>[expr $price * ($fuzzie_wordcount)]</td>
        </tr>"

    # Int. Repetitions
    append task_table_rows "
        <input type=hidden name=im_trans_task value=$task_id>
        <tr $bgcolor([expr $ctr % 2])>
          <td align=left></td>
          <td align=right>[lang::message::lookup "" intranet-core.doc_descr "Int. Repetitions" ]</td>
          <td align=right>$int_repetitions</td>
          <td align=right>[expr $trados_array(rep) * 100 ]%</td>
          <td align=right>[expr $trados_array(rep) * $int_repetitions ]</td>
          <td>$price</td>
          <td>[expr $price * [expr $trados_array(rep) * $int_repetitions ] ]</td>
        </tr>"
    # 100% matches
    append task_table_rows "
        <input type=hidden name=im_trans_task value=$task_id>
        <tr $bgcolor([expr $ctr % 2])>
          <td align=left></td>
          <td align=right>[lang::message::lookup "" intranet-core.doc_descr "100% matches" ]</td>
          <td align=right>$match100</td>
          <td align=right>[expr $trados_array(100) * 100 ]%</td>
          <td align=right>[expr $trados_array(100) * $match100 ]</td>
          <td>$price</td>
          <td>[expr $price * [expr $trados_array(100) * $match100]]</td>
        </tr>"

    incr ctr
}

if {[string equal "" $task_table_rows]} {
    append task_table_rows "<tr><td colspan=$colspan align=center>[_ intranet-trans-invoices.No_tasks_found]</td></tr>"
}

append task_table_rows "</table>"

db_1row receipent_get_info "
	select 
		* 
	from 
		im_companies 
	where 
		company_id = (
				select 
					company_id 
				from 
					im_projects 
				where 
					project_id = :project_id 
				)
" 

db_1row sender_get_accounting_contact "
	select
        	pe.first_names as accounting_first_name,
                pe.last_name as accounting_last_name
        from
                persons pe
        where
                person_id = $accounting_contact_id
"
db_1row sender_get_address "

                       select
                                o.office_name as name_string,
                                o.address_line1 as address_line1,
                                o.address_line2 as address_line2,
                                o.address_city as city,
                                o.address_state as state,
                                o.address_postal_code as postal_code,
                                o.address_country_code as country_code_id,
                                o.note as note,
                                o.phone as office_phone,
                                o.fax as office_fax,
                                c.vat_number as vat,
                                c.site_concept as office_site
                        from
                                im_offices o,
                                im_companies c
                        where
                                o.office_id = c.main_office_id and
                                c.company_id = $company_id
"


        set accounting_html "
                <tr><td class='address'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Attn:&nbsp;$accounting_first_name&nbsp;$accounting_last_name</td></tr>
        "
	set country_name [db_string company_get_cc "select cc.country_name from country_codes cc where cc.iso = :country_code_id" -default ""]


set address_html " 

	<table width=\"95%\" border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
	  <tr>
	    <td valign=\"top\" width=60%>
		<br><br><br><table border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
	        <tr class=rowtitle><td colspan=\"2\" class=rowtitle></td></tr>
		<tr><td class=\"address\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>$company_name </b></td></tr>
	        $accounting_html
		<tr><td class=\"address\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$address_line1  $address_line2 </td></tr>
		<tr><td class=\"address\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$postal_code  $city </td></tr>
		<tr><td class=\"address\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$country_name </td></tr>
"

	ns_write "
		<html>
		 <head>
		  <meta http-equiv='content-type' content='text/html;charset=UTF-8'>
		  <title>$page_title</title>
		  <link rel='stylesheet' type='text/css' href='/intranet-reporting-translation/project-trans-tasks-details-2.css'>
		 </head>
		 <body>
		  <div id=header>
		   <p style='text-align:right'>[im_logo]</p>
		  </div>
		  <div id=main>
			<div id=title>$address_html</div>
			<!--
			<table id=headertable cellpadding=0 border=0 rules=all>
			 <tbody>
			  <tr>
			   <td id=head>$customer_l10n:</td>
			   <td id=head>$customer_po_l10n:</td>
			  </tr>
			  
			  <tr>
			   <td id=content>customer_name</td>
			   <td id=content></td>
			  </tr>
			  
			 </tbody>
			</table>
			--> 
			$table_header_html
			$task_table_rows
		</div>
		<br><br><br><br>
		</body>
	    </html>
\	"
