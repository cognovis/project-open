# /packages/intranet-timesheet2-invoices/www/new-3.tcl
#
# Copyright (C) 2003-2004 Project/Open
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
    @param include_task A list of im_timesheet_task IDs to include in the
           new invoice
    @param company_id All include_tasks need to be from the same
           company.
    @param invoice_currency: EUR or USD

    @author frank.bergmann@project-open.com
} {
    include_task:multiple
    company_id:integer
    invoice_currency
    invoice_hour_type
    select_project
    start_date
    end_date
    { cost_center_id:integer 0}
    target_cost_type_id:integer
    { return_url ""}
    { aggregate_tasks_p "0" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set org_company_id $company_id

set number_format "99990.099"
set date_format "YYYY-MM-DD"
set cost_type_invoice [im_cost_type_invoice]
set target_cost_type [im_category_from_id $target_cost_type_id]
set target_cost_type_mangle [lang::util::suggest_key $target_cost_type]

set invoicing_start_date $start_date
set invoicing_end_date $end_date

if {"" == $return_url} {set return_url [im_url_with_query] }
set todays_date [db_string get_today "select to_char(now(), :date_format)"]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-timesheet2-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-timesheet2-invoices.lt_You_dont_have_suffici]"    
}

set allowed_cost_type [im_cost_type_write_permissions $user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}


# ---------------------------------------------------------------
# Gather invoice data
# ---------------------------------------------------------------

# Build the list of selected tasks ready for invoicing
set in_clause_list [list]
foreach selected_task $include_task {
    lappend in_clause_list $selected_task
}
set tasks_where_clause "p.project_id in ([join $in_clause_list ","])"

# We already know that all tasks are from the same company,
# and we asume that the company_id is set from new-2.tcl.

if { [catch {
    db_1row invoices_info_query ""
} err_msg] } {
    ad_return_complaint 1 [lang::message::lookup "" intranet-timesheet2-invoices.Company_not_found "We didn't find any information about company\# %company_id%."]
}


# Default for cost-centers - take the user's
# dept from HR.
if {0 == $cost_center_id} {
    set cost_center_id [im_costs_default_cost_center_for_user $user_id]
}

set cost_center_label [lang::message::lookup "" intranet-invoices.Cost_Center "Cost Center"]
set cost_center_select [im_cost_center_select -include_empty 1 -department_only_p 0 cost_center_id $cost_center_id $target_cost_type_id]


set default_material_id [im_material_default_material_id]
set default_material_name [db_string matname "select acs_object__name(:default_material_id)"]
set default_uom_id [db_string default_uom "select material_uom_id from im_materials where material_id = :default_material_id"]

# ---------------------------------------------------------------
# Determine the contact for the invoice

set contact_ids [db_list contact_ids "
        select distinct
		company_contact_id
	from	im_timesheet_tasks t,
		im_projects p
	where	t.task_id = p.project_id and 
		$tasks_where_clause
"]

if {[llength $contact_ids] > 0} {
    set company_contact_id [lindex $contact_ids 0]
} else {
    set company_contact_id $accounting_contact_id
}

db_1row accounting_contact_info "
    select
        im_name_from_user_id(:company_contact_id) as company_contact_name,
        im_email_from_user_id(:company_contact_id) as company_contact_email
"

set invoice_office_id [db_string company_main_office_info "
	select	main_office_id 
	from	im_companies
	where	company_id = :org_company_id
" -default ""]


# ---------------------------------------------------------------
# Create the default values for a new invoice.
#
# Calculate the next invoice number by calculating the maximum of
# the "reasonably build numbers" currently available

set button_text [lang::message::lookup "" intranet-timesheet2-invoices.Create_$target_cost_type_mangle "Create $target_cost_type"]
set page_title [lang::message::lookup "" intranet-timesheet2-invoices.New_$target_cost_type_mangle "New $target_cost_type"]

set context_bar [im_context_bar [list /intranet/invoices/ "[_ intranet-timesheet2-invoices.Invoices]"] $page_title]
set invoice_id [im_new_object_id]
set invoice_nr [im_next_invoice_nr -invoice_type_id $target_cost_type_id]
set invoice_date $todays_date
set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultCompanyInvoicePaymentDays" "" 30] 
set due_date [db_string get_due_date "select to_date(to_char(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD') + $payment_days from dual"]
set provider_id [im_company_internal]
set customer_id $company_id

set cost_type_id $target_cost_type_id

set cost_status_id [im_cost_status_created]
set vat 0
set tax 0
set note ""
set payment_method_id ""
set template_id ""


# ---------------------------------------------------------------
# 7. Select and format the sum of the invoicable items
# for a new invoice
# ---------------------------------------------------------------

# start formatting the list of sums with the header...
set task_sum_html "
        <tr align=center> 
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Order]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Description]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Units]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.UOM]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Rate]</td>
        </tr>
"

# Start formatting the "reference price list" as well, even though it's going
# to be shown at the very bottom of the page.
#
set price_colspan 11
set reference_price_html "
        <tr><td align=middle class=rowtitle colspan=$price_colspan>[_ intranet-timesheet2-invoices.Reference_Prices]</td></tr>
        <tr>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Company]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.UoM]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Task_Type]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Material]</td>
<!--          <td class=rowtitle>[_ intranet-timesheet2-invoices.Valid_From]</td>	-->
<!--          <td class=rowtitle>[_ intranet-timesheet2-invoices.Valid_Through]</td>	-->
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Price]</td>
        </tr>\n"


if {$aggregate_tasks_p} {

    # Calculate the sum of tasks (distinct by TaskType and UnitOfMeasure)
    # and determine the price of each line using a custom definable
    # function.
    set task_sum_inner_sql "
		select
			sum(t.planned_units) as planned_sum,
			sum(t.billable_units) as billable_sum,
			sum(t.reported_units) as reported_sum,
			sum(t.hours_in_interval) as interval_sum,
			parent.project_id as project_id,	
			im_material_name_from_id(t.task_material_id) as task_name,
			t.task_type_id,
			t.uom_id,
			t.company_id,
			t.task_material_id as material_id
		from
			(select
				t.planned_units,
				t.billable_units,
				(select sum(h.hours) from im_hours h where h.project_id = p.project_id) as reported_units,
				(select sum(h.hours) from im_hours h where
					h.project_id = p.project_id
					and h.day >= to_timestamp(:invoicing_start_date, 'YYYY-MM-DD')
					and h.day < to_timestamp(:invoicing_end_date, 'YYYY-MM-DD')
				) as hours_in_interval,
				parent.project_id as project_id,	
				coalesce(t.material_id, :default_material_id) as task_material_id,
				coalesce(t.uom_id, :default_uom_id) as uom_id,
				p.project_type_id as task_type_id,
				p.company_id
			from 
				im_projects parent,
				im_projects p
				LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
			where 
				$tasks_where_clause
				and parent.parent_id is null
				and p.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
			) t,
			im_projects parent
		where
			t.project_id = parent.project_id
		group by
			t.task_material_id,
			t.task_type_id,
			t.uom_id,
			t.company_id,
			parent.project_id
    "

} else {

    # Don't aggregate - just show the list of tasks
    #
    set task_sum_inner_sql "
	select
		t.planned_units as planned_sum,
		t.billable_units as billable_sum,
		(select sum(h.hours) from im_hours h where h.project_id = p.project_id) as reported_sum,
		(select sum(h.hours) from im_hours h where
			h.project_id = p.project_id
			and h.day >= to_timestamp(:invoicing_start_date, 'YYYY-MM-DD')
			and h.day < to_timestamp(:invoicing_end_date, 'YYYY-MM-DD')
		) as interval_sum,

		p.company_id,
		parent.project_id,
		p.project_name as task_name,
		p.project_type_id as task_type_id,
		coalesce(t.uom_id, :default_uom_id) as uom_id,
		coalesce(t.material_id, :default_material_id) as material_id
	from
		im_projects parent,
		im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
	where
		$tasks_where_clause
		and parent.parent_id is null
		and p.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
    "
}


    # Calculate the price for the specific service.
    # Complicated undertaking, because the price depends on a number of variables,
    # depending on client etc. As a solution, we act like a search engine, return 
    # all prices and rank them according to relevancy. We take only the first 
    # (=highest rank) line for the actual price proposal.
    #
    set reference_price_sql "
select 
	p.relevancy as price_relevancy,
	trim(' ' from to_char(p.price,:number_format)) as price,
	p.company_id as price_company_id,
	p.uom_id as uom_id,
	p.task_type_id as task_type_id,
	p.material_id as material_id,
	p.valid_from,
	p.valid_through,
	c.company_path as price_company_name,
	im_category_from_id(p.uom_id) as price_uom,
	im_category_from_id(p.task_type_id) as price_task_type,
	im_category_from_id(p.material_id) as price_material
from
	(
		(select 
			im_timesheet_prices_calc_relevancy (
				p.company_id,:company_id,
				p.task_type_id, :task_type_id,
				p.material_id, :material_id
			) as relevancy,
			p.price,
			p.company_id,
			p.uom_id,
			p.task_type_id,
			p.material_id,
			p.valid_from,
			p.valid_through
		from im_timesheet_prices p
		where
			uom_id=:uom_id
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

    set task_sum_sql "
	select
		trim(both ' ' from to_char(s.planned_sum, :number_format)) as planned_sum,
		trim(both ' ' from to_char(s.billable_sum, :number_format)) as billable_sum,
		trim(both ' ' from to_char(s.reported_sum, :number_format)) as reported_sum,
		trim(both ' ' from to_char(s.interval_sum, :number_format)) as interval_sum,
		s.task_type_id,
		s.material_id,
		s.task_name,
		s.uom_id,
		im_category_from_id(s.uom_id) as task_uom,
		im_category_from_id(s.task_type_id) as task_type,
		s.company_id,
		s.project_id,
		p.project_name,
		p.project_path,
		p.project_path as project_short_name,
		p.project_nr
	from
		($task_sum_inner_sql) s
		LEFT JOIN im_projects p ON (s.project_id = p.project_id)
	order by
		p.project_id
    "

    set ctr 1
    set old_project_id 0
    set colspan 6
    db_foreach tasks $task_sum_sql {

	set task_sum 0
	switch $invoice_hour_type {
	    planned { set task_sum $planned_sum }
	    billable { set task_sum $billable_sum }
	    reported { set task_sum $reported_sum }
	    interval { set task_sum $interval_sum }
	}

	if {"" == $task_sum} { continue }
	if {0 == $task_sum} { continue }

	# insert intermediate headers for every project
	if {$old_project_id != $project_id} {
	    append task_sum_html "
		<tr><td class=rowtitle colspan=$price_colspan>
		  <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
		  $project_nr
		</td></tr>\n"

	    # Also add an intermediate header to the price list
	    append reference_price_html "
		<tr><td class=rowtitle colspan=$price_colspan>
		  <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
		  $project_nr
		</td></tr>\n"
	
	    set old_project_id $project_id
	}

	# Determine the price from a ranked list of "price list hits"
	# and render the "reference price list"
	set price_list_ctr 1
	set best_match_price 0
	db_foreach references_prices $reference_price_sql {

	    ns_log Notice "new-3: company_id=$company_id, uom_id=$uom_id => price=$price, relevancy=$price_relevancy"
	    # Take the first line of the result list (=best score) as a price proposal:
	    if {$price_list_ctr == 1} {set best_match_price $price}

	    append reference_price_html "
	<tr>
	  <td class=$bgcolor([expr $price_list_ctr % 2])>$price_company_name</td>
	  <td class=$bgcolor([expr $price_list_ctr % 2])>$price_uom</td>
	  <td class=$bgcolor([expr $price_list_ctr % 2])>$price_task_type</td>
	  <td class=$bgcolor([expr $price_list_ctr % 2])>$price_material</td>
<!--	  <td class=$bgcolor([expr $price_list_ctr % 2])>$valid_from</td>		-->
<!--	  <td class=$bgcolor([expr $price_list_ctr % 2])>$valid_through</td> 	-->
	  <td class=$bgcolor([expr $price_list_ctr % 2])>$price $invoice_currency</td>
	</tr>\n"
	
	    incr price_list_ctr
	}

	# Add an empty line to the price list to separate prices form item to item
	append reference_price_html "<tr><td colspan=$price_colspan>&nbsp;</td></tr>\n"

	append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
	  <td>
	    <input type=text name=item_sort_order.$ctr size=2 value='$ctr'>
	  </td>
	  <td>
	    <input type=text name=item_name.$ctr size=40 value='$task_name'>
	  </td>
	  <td align=right>
	    <input type=text name=item_units.$ctr size=4 value='$task_sum'>
	  </td>
	  <td align=right>
	    <input type=hidden name=item_uom_id.$ctr value='$uom_id'>
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
    }


# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

set include_task_html ""
foreach task_id $in_clause_list {
    append include_task_html "<input type=hidden name=include_task value=$task_id>\n"
}


