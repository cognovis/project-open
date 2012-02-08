# /packages/intranet-trans-invoices/www/new-3.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Receives the list of tasks to invoice and creates an invoice form
    similar to /intranet-invoicing/www/new in order to create a new
    invoice.<br>
    @param include_task A list of im_trans_task IDs to include in the
           new invoice
    @param company_id All include_tasks need to be from the same
           company.
    @param invoice_currency: EUR or USD

    @author frank.bergmann@project-open.com
} {
    include_task:multiple
    company_id:integer
    invoice_currency
    target_cost_type_id:integer
    { view_name "invoice_tasks" }
    { order_by "Project nr" }
    { cost_center_id:integer 0}
    { aggregate_tasks_p "0" }
    { return_url ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set org_company_id $company_id

if {"" == $return_url} {set return_url [im_url_with_query] }
set todays_date [db_string get_today "select now()::date"]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"
set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"
set price_url_base "/intranet-trans-invoices/price-lists/new"

set number_format 999999999999D

for { set i 0 } { $i <= [expr [parameter::get_from_package_key -package_key intranet-invoices -parameter "AccuracyFinDocItems" -default 2] -1 ] } { incr i } {
    append number_format "0"
}

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-trans-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-trans-invoices.lt_You_dont_have_suffici]"    
}

set allowed_cost_type [im_cost_type_write_permissions $user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}

# Default for cost-centers - take the user's
# dept from HR.
if {0 == $cost_center_id} {
    set cost_center_id [im_costs_default_cost_center_for_user $user_id]
}

set cost_center_label [lang::message::lookup "" intranet-invoices.Cost_Center "Cost Center"]
set cost_center_select [im_cost_center_select -include_empty 1 -department_only_p 0 cost_center_id $cost_center_id $target_cost_type_id]


# ---------------------------------------------------------------
# Gather invoice data
# ---------------------------------------------------------------

# Build the list of selected tasks ready for invoicing
set in_clause_list [list]
foreach selected_task $include_task {
    lappend in_clause_list $selected_task
}
set tasks_where_clause "task_id in ([join $in_clause_list ","])"

set cost_type_invoice_id [im_cost_type_invoice]
set cost_type_id $target_cost_type_id
set type_name [db_string type_name "select im_category_from_id(:target_cost_type_id)"]
set button_text "[_ intranet-trans-invoices.Create_Invoice]"
set page_title "[_ intranet-trans-invoices.New_Invoice]"
set context_bar [im_context_bar [list /intranet/invoices/ "[_ intranet-trans-invoices.Finance]"] $page_title]
set invoice_id [im_new_object_id]
set invoice_nr [im_next_invoice_nr -cost_type_id $target_cost_type_id]
set invoice_date $todays_date
set default_payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultCompanyInvoicePaymentDays" "" 30] 
set enable_file_type_p [parameter::get_from_package_key -package_key intranet-trans-invoices -parameter "EnableFileTypeInTranslationPriceList" -default 0]
set due_date [db_string get_due_date "select to_date(to_char(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD') + $default_payment_days from dual"]
set provider_id [im_company_internal]
set customer_id $company_id
set cost_status_id [im_cost_status_created]
set tax 0
set note ""
set default_vat 0
set default_tax 0
set default_payment_method_id ""
set default_invoice_template_id ""

# ---------------------------------------------------------------
# Gather company data from company_id
# ---------------------------------------------------------------

db_1row invoices_info_query ""

# Logic to determine the default contact for this invoice.
# This logic only makes sense if there is exactly one
# project to be invoiced.
set project_ids [db_list project_list "
	select distinct project_id
	from im_trans_tasks
	where $tasks_where_clause
"]

set company_contact_id $accounting_contact_id
if {1 == [llength $project_ids]} { 
    set project_id [lindex $project_ids 0]
    set company_contact_id [im_invoices_default_company_contact $customer_id $project_id]
}

db_1row accounting_contact_info "
    select
        im_name_from_user_id(:company_contact_id) as company_contact_name,
        im_email_from_user_id(:company_contact_id) as company_contact_email
    "

set invoice_office_id [db_string company_main_office_info "select main_office_id from im_companies where company_id = :org_company_id" -default ""]



# ---------------------------------------------------------------
# Determine headers / order by clause
# ---------------------------------------------------------------

set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br>
    Maybe you need to upgrade the database. <br>
    Please notify your system administrator."
    return
}


set column_headers [list]
set column_vars [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set column_sql "
select
        vc.*
from
        im_view_columns vc
where
        view_id=:view_id
        and group_id is null
order by
        sort_order"

db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
        lappend column_headers "$column_name"
        lappend column_vars "$column_render_tcl"
        if {"" != $extra_select} { lappend extra_selects $extra_select }
        if {"" != $extra_from} { lappend extra_froms $extra_from }
        if {"" != $extra_where} { lappend extra_wheres $extra_where }
        # ad_return_complaint 1 [lappend $order_by_clause "-"  $order_by "-" $column_name]
        if {"" != $order_by_clause && $order_by==$column_name} {
            set view_order_by_clause $order_by_clause
        }
    }
}


# ad_return_complaint 1 $view_order_by_clause

if {$view_order_by_clause != ""} {
    if { $view_order_by_clause == "task_status" } {
                        set order_by_clause "p.project_id, task_status ASC, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "t.task_name" } {
                        set order_by_clause "p.project_id, task_name ASC, type_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "t.task_units" } {
                        set order_by_clause "p.project_id, t.task_units, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "t.billable_units" } {
                        set order_by_clause "p.project_id, t.billable_units, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "type_name" } {
                        set order_by_clause "p.project_id, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "t.task_uom_id" } {
                        set order_by_clause "p.project_id, uom_name, type_name ASC, task_name ASC, target_language ASC"
    } elseif { $view_order_by_clause == "target_language" } {
                        set order_by_clause "p.project_id, target_language ASC, type_name ASC, task_name ASC"
    } else {
                        set order_by_clause "p.project_id, task_name ASC, type_name, target_language"
    }
} else {
            set order_by_clause "t.task_name"
}




# ad_return_complaint 1 $order_by_clause

# ---------------------------------------------------------------
# 6. Select and render invoicable items 
# ---------------------------------------------------------------

# Always generaet the tasks table because:
# - Show the same screen - make it easier for the user
# - It includes the hidden variables "im_trans_task" necessary for new-4
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
		im_category_from_id(t.task_uom_id) as uom_name,
		im_category_from_id(t.task_type_id) as type_name,
		im_category_from_id(t.task_status_id) as task_status,
		im_category_from_id(t.target_language_id) as target_language,
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


ns_log Notice "before rendering the task list $invoice_id"

set task_table_rows ""
set ctr 0
set colspan 7
set old_project_id 0
db_foreach select_tasks $sql {

    # insert intermediate headers for every project
    if {$old_project_id != $project_id} {
	append task_table_rows "
		<tr><td colspan=$colspan>&nbsp;</td></tr>
		<tr>
		  <td class=rowtitle colspan=$colspan>
	            <A href=/intranet/projects/view?project_id=$project_id>
		      $project_short_name
		    </A>: $project_name
	          </td>
		  <input type=hidden name=select_project value=$project_id>
		</tr>\n"
	set old_project_id $project_id
    }

    append task_table_rows "
        <input type=hidden name=im_trans_task value=$task_id>
	<tr $bgcolor([expr $ctr % 2])> 
	  <td align=left>$task_name</td>
	  <td align=right>$task_units</td>
	  <td align=right>$billable_units</td>
	  <td align=right>$target_language</td>
	  <td align=right>$uom_name</td>
	  <td>$type_name</td>
	  <td>$task_status</td>
	</tr>"
    incr ctr
}

if {[string equal "" $task_table_rows]} {
    append task_table_rows "<tr><td colspan=$colspan align=center>[_ intranet-trans-invoices.No_tasks_found]</td></tr>"
}



# ---------------------------------------------------------------
# Select and format the sum of the invoicable items
# for a new invoice
# ---------------------------------------------------------------

# Start formatting the "reference price list" as well, even though it's going
# to be shown at the very bottom of the page.
#
set price_colspan 12
if {$enable_file_type_p} { incr price_colspan}

set file_type_html "<td class=rowtitle>[lang::message::lookup "" intranet-trans-invoices.File_Type "File Type"]</td>"
if {!$enable_file_type_p} { set file_type_html "" }


# set order_by_clause "p.project_id, t.task_uom_id"
# ad_return_complaint 1 $order_by_clause

if {$aggregate_tasks_p} {

	if {$view_order_by_clause != ""} {
		if {$view_order_by_clause == "t.billable_units"} {
			set order_by_clause "p.project_id, task_sum"
		} elseif {$view_order_by_clause == "task_status"  || $view_order_by_clause == "t.task_name"} {
			set order_by_clause "p.project_id"
		} elseif {$view_order_by_clause == "t.task_units"} {
        	        set order_by_clause "p.project_id, task_sum"
		} else {
        	        set order_by_clause "p.project_id"
		}
	} else {
	    set order_by_clause "p.project_id"
	}
    
    # Calculate the sum of tasks (distinct by TaskType and UnitOfMeasure)
    # and determine the price of each line using a custom definable
    # function.
    set task_sum_inner_sql "
	select
                sum(coalesce(s.billable_units,0)) as task_sum,
                '' as task_title,
                s.task_type_id,
                s.task_uom_id,
                s.source_language_id,
                s.target_language_id,
                p.company_id,
                p.project_id,
                p.subject_area_id,
                im_file_type_from_trans_task(s.task_id) as file_type_id
	from 
		im_trans_tasks s,
		im_projects p
	where 
		$tasks_where_clause
		and s.project_id=p.project_id
	group by
                s.task_type_id,
                s.task_uom_id,
                p.company_id,
                p.project_id,
                s.source_language_id,
                s.target_language_id,
                p.subject_area_id,
                file_type_id
		"

    # Take the "Inner Query" with the data (above) and add some "long names" 
    # (categories, client names, ...) for pretty output
    set task_sum_sql "
		select
			trim(both ' ' from to_char(t.task_sum, :number_format)) as task_sum,
			t.task_type_id,
			t.subject_area_id,
			t.file_type_id,
			t.source_language_id,
			t.target_language_id,
			t.task_uom_id,
			c_type.category as task_type,
			c_uom.category as task_uom,
			c_target.category as target_language,
			t.company_id,
			t.project_id,
			p.project_name,
			p.project_path,
			p.project_path as project_short_name,
			p.company_project_nr
		from
			($task_sum_inner_sql) t
		      LEFT JOIN
			im_categories c_uom ON t.task_uom_id=c_uom.category_id
		      LEFT JOIN
			im_categories c_type ON t.task_type_id=c_type.category_id
		      LEFT JOIN
			im_categories c_target ON t.target_language_id=c_target.category_id
		      LEFT JOIN
			im_projects p ON t.project_id=p.project_id
	order by
	        $order_by_clause
    "
	
} else {

    # Don't aggregate Tasks - Just create a list of the task

	if {$view_order_by_clause != ""} {
	    if { $view_order_by_clause == "task_status" } {
                        set order_by_clause "p.project_id, task_status ASC, type_name ASC, task_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "t.task_name" } {
                        set order_by_clause "p.project_id, task_name ASC, type_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "t.task_units" } {
                        set order_by_clause "p.project_id, t.task_units, type_name ASC, task_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "t.billable_units" } {
                        set order_by_clause "p.project_id, t.billable_units, type_name ASC, task_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "type_name" } {
                        set order_by_clause "p.project_id, type_name ASC, task_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "t.task_uom_id" } {
                        set order_by_clause "p.project_id, task_uom, type_name ASC, task_name ASC, target_language ASC"
	    } elseif { $view_order_by_clause == "target_language" } {
                        set order_by_clause "p.project_id, target_language ASC, type_name ASC, task_name ASC"
	    } else {
                        set order_by_clause "p.project_id, task_name ASC, type_name ASC, target_language ASC"
	    }
	} else {
        	set order_by_clause "t.task_name"
	}


    set task_sum_sql "
	select
		t.source_language_id,
		t.target_language_id,
		t.task_name || 
			' (' || im_category_from_id(t.source_language_id) || 
			' -> ' || im_category_from_id(t.target_language_id) || ')'
			as task_title,
		coalesce(t.billable_units,0) as task_sum,
		t.task_uom_id,
		t.task_type_id,
		im_file_type_from_trans_task(t.task_id) as file_type_id,
	        im_category_from_id(t.task_type_id) as task_type,
	        im_category_from_id(t.task_uom_id) as task_uom,
	        im_category_from_id(t.target_language_id) as target_language,
                im_category_from_id(t.task_type_id) as type_name,
                im_category_from_id(t.task_status_id) as task_status,
	        p.project_name,
	        p.project_path,
	        p.project_path as project_short_name,
	        p.company_project_nr,
		p.subject_area_id
	from
	        im_trans_tasks t
	    LEFT JOIN
	        im_projects p ON (t.project_id = p.project_id)
	where
		$tasks_where_clause
		and t.project_id=p.project_id
	order by 
		$order_by_clause
        "
}

# ad_return_complaint 1 $task_sum_sql
# db_foreach task_sum_query $task_sum_sql { ad_return_complaint 1 "uom=[im_category_from_id $task_uom_id], title=$task_title" }


# ---------------------------------------------------------------
# Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
ns_log Notice "/intranet/project/index: Before format header"
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""

# Format the header names with links that modify the
# sort order of the SQL query.
#

set url "new-3?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"

foreach col $column_headers {
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]

    if { [string compare $order_by $col] == 0 } {
        append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    } else {

        #set col [lang::util::suggest_key $col]
        append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a></td>\n"
    }
}

append table_header_html "</tr>\n"


# ad_return_complaint 1 $table_header_html


# ---------------------------------------------------------------
# Format Task Sum Header
# ---------------------------------------------------------------

set task_sum_header_html ""

foreach col $column_headers {
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]

    # ad_return_complaint 1 $col_txt

    if { $col_txt == $col_txt } {
	if { [string compare $order_by $col] == 0 } {
	    append task_sum_header_html "  <td class=rowtitle>$col_txt</td>\n"
	} else {
	    #set col [lang::util::suggest_key $col]
	    append task_sum_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a></td>\n"
	}
    }

}
append task_sum_header_html "</tr>\n"

# Description Units UOM Rate

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------


# Calculate the price for the specific service.
# Complicated undertaking, because the price depends on a number of variables,
# depending on client etc. As a solution, we act like a search engine, return 
# all prices and rank them according to relevancy. We take only the first 
# (=highest rank) line for the actual price proposal.
#
set reference_price_sql "
select 
	p.price_id,
	p.relevancy as price_relevancy,
	p.price,
	trim(' ' from to_char(p.price,:number_format)) as price_formatted,
	p.min_price,
	trim(' ' from to_char(p.min_price,:number_format)) as min_price_formatted,
	p.company_id as price_company_id,
	p.uom_id as uom_id,
	p.task_type_id as task_type_id,
	p.target_language_id as target_language_id,
	p.source_language_id as source_language_id,
	p.subject_area_id as subject_area_id,
	p.file_type_id as file_type_id,
	p.valid_from,
	p.valid_through,
	p.price_note,
	c.company_path as price_company_name,
        im_category_from_id(p.uom_id) as price_uom,
        im_category_from_id(p.task_type_id) as price_task_type,
        im_category_from_id(p.target_language_id) as price_target_language,
        im_category_from_id(p.source_language_id) as price_source_language,
        im_category_from_id(p.subject_area_id) as price_subject_area,
        im_category_from_id(p.file_type_id) as price_file_type
from
	(
		(select 
			im_trans_prices_calc_relevancy (
				p.company_id,:company_id,
				p.task_type_id, :task_type_id,
				p.subject_area_id, :subject_area_id,
				p.target_language_id, :target_language_id,
				p.source_language_id, :source_language_id,
				p.file_type_id, :file_type_id
			) as relevancy,
			p.price_id,
			p.price,
			p.min_price,
			p.company_id,
			p.uom_id,
			p.task_type_id,
			p.target_language_id,
			p.source_language_id,
			p.subject_area_id,
			p.file_type_id,
			p.valid_from,
			p.valid_through,
			p.note as price_note
		from im_trans_prices p
		where
			uom_id=:task_uom_id
			and currency=:invoice_currency
		)
	) p,
	im_companies c
where
	p.company_id=c.company_id
	and relevancy >= 0
order by
	p.relevancy desc,
	p.company_id,
	p.uom_id
"


set ctr 1
set old_project_id 0
set colspan 6
set target_language_id ""
set task_title ""
set reference_price_html ""
set task_sum_html ""

db_foreach task_sum_query $task_sum_sql {

    ns_log Notice "new-3: src=[im_category_from_id $source_language_id], tgt=$target_language, type=$task_type, uom=$task_uom_id, uom=$task_uom, sub=[im_category_from_id $subject_area_id]"

    # Make sure the material exists.
    # The procedure will peek variables defined in DynFields of im_material
    # from the current stack environment
    set material_id [im_material_create_from_parameters -material_uom_id $task_uom_id -material_type_id [im_material_type_translation] -debug 1]

    # insert intermediate headers for every project
    if {$old_project_id != $project_id} {
	append task_sum_html "
		<tr class=rowtitle><td class=rowtitle colspan=$price_colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $company_project_nr
	        </td></tr>\n"

	# Also add an intermediate header to the price list
	append reference_price_html "
		<tr class=rowtitle><td class=rowtitle colspan=$price_colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $company_project_nr
	        </td></tr>\n"
	
	set old_project_id $project_id
    }
    
    if {"" == $task_title} {
	set msg_key [lang::util::suggest_key $task_type]
	set task_type_l10n [lang::message::lookup "" intranet-core.$msg_key $task_type]
	set msg_key [lang::util::suggest_key $target_language]
	set target_language_l10n [lang::message::lookup "" intranet-core.$msg_key $target_language]
	set task_title [lang::message::lookup "" intranet-trans-invoices.Task_Title_Format "%task_type_l10n% (%target_language_l10n%)"]
    }

    
    # Determine the price from a ranked list of "price list hits"
    # and render the "reference price list"
    set price_list_ctr 1
    set best_match_price 0
    set best_match_min_price 0

    db_foreach references_prices $reference_price_sql {
	
	ns_log Notice "new-3: company_id=$company_id, uom_id=$uom_id => price=$price_formatted, relevancy=$price_relevancy"

	# Take the first line of the result list (=best score) as a price proposal:
	if {$price_list_ctr == 1} {
	    set best_match_price $price_formatted
	    set best_match_min_price $min_price
	    set best_match_price_id $price_id
	}
	
	set price_url [export_vars -base $price_url_base { company_id price_id return_url }]
	
	set file_type_html "<td class=$bgcolor([expr $price_list_ctr % 2])>$price_file_type</td>"
	if {!$enable_file_type_p} { set file_type_html "" }
	
	set min_price_formatted "$min_price_formatted $invoice_currency"
	if {"" == $min_price} { set min_price_formatted "" }

	set company_price_url [export_vars -base "/intranet/companies/view" { {company_id $price_company_id} return_url }]
	set company_html "<a href=\"$company_price_url\">$price_company_name</a>"
	append reference_price_html "
	        <tr>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_relevancy</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$company_html</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_uom</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_task_type</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_target_language</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_source_language</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_subject_area</td>
		  $file_type_html
	          <td class=$bgcolor([expr $price_list_ctr % 2])>[string_truncate -len 30 $price_note]</td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>
			<a href=\"$price_url\">$price_formatted $invoice_currency</a>
		  </td>
	          <td class=$bgcolor([expr $price_list_ctr % 2])>$min_price_formatted</td>
	        </tr>
	    "
	
	incr price_list_ctr
    }

    # Minimum Price Logic
    if {[expr $best_match_price * $task_sum] < $best_match_min_price} {
	set task_sum 1
	set task_title "$task_title [lang::message::lookup "" intranet-trans-invoices.Min_Price_Min "(Minimum Fee)"]"
	set task_uom_id [im_uom_unit]
	set task_uom [im_category_from_id $task_uom_id]
	set best_match_price $best_match_min_price
    }
    
    # Add an empty line to the price list to separate prices form item to item
    append reference_price_html "<tr><td colspan=$price_colspan>&nbsp;</td></tr>\n"

# Debug to show material_id and name
#	    $material_id [db_string mn "select material_name from im_materials where material_id = :material_id" -default "unknown"]
     
    append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
          <td>
	    <input type=text name=item_sort_order.$ctr size=2 value='$ctr'>
	  </td>
          <td>
	    <input type=text name=item_name.$ctr size=40 value='[ns_quotehtml $task_title]'>
	    <input type=hidden name=item_material_id.$ctr value='$material_id'>
	  </td>

          <td align=right>
	    <input type=text name=item_units.$ctr size=4 value='$task_sum'>
	  </td>
          <td align=right>
	    <input type=hidden name=item_uom_id.$ctr value='$task_uom_id'>
	    $task_uom
	  </td>
          <td align=right>
	    <input type=text name=item_rate.$ctr size=3 value='$best_match_price'>
	    <input type=hidden name=item_currency.$ctr value='$invoice_currency'>
	    $invoice_currency
	  </td>
        </tr>
	<input type=hidden name=item_project_id.$ctr value='$project_id'>
	<input type=hidden name=item_type_id.$ctr value='$task_type_id'>\n"

    incr ctr
    set task_title ""
}


# ad_return_complaint 1 $task_sum_html
