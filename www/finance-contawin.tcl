# /packages/intranet-reporting-finance/www/finance-contawin.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { start_date "" }
    { end_date "" }
    { number_locale "" }
    { level_of_detail:integer 2 }
    { output_format "html" }
    { sales_cc_id:integer 0 }
    { production_cc_id:integer 0 }
    { invoicing_cc_id:integer 0 }
    { internal_contact_id:integer 0 }
    { cost_type_id:integer 3700 }
    customer_id:integer,optional
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-finance-contawin"
set current_user_id [ad_maybe_redirect_for_registration]

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}


# ------------------------------------------------------------
# Deal with invoices related to multiple projects

im_invoices_check_for_multi_project_invoices


# ------------------------------------------------------------
# Page Settings

set page_title "ContaWin Export"
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong>ContaWin Accounting Export:</strong><p>

The puprpose of this report is to provide CSV data suitable for the import into 
the Spanish 'ContaWin' accounting software. <p>
The report shows all 'Customer Invoices' / 'Provider Bills' with the effective 
date between Start Date and End Date. <p>
Start Date is inclusive (document with effective date = Start Date or later), 
while End Date is exclusive (documents earlier then End Date, exclucing End Date).
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set days_in_past 7

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} { 
    set start_date "$todays_year-$todays_month-01"
}

# Maxlevel is 4. Normalize in order to show the right drop-down element
if {$level_of_detail > 3} { set level_of_detail 3 }


db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "$end_year-$end_month-01"
}


set company_url "/intranet/companies/view?company_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-finance/finance-contawin" {start_date end_date} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {[info exists customer_id] && 0 != $customer_id && "" != $customer_id} {
    lappend criteria "cust.company_id = :customer_id"
}

if {[info exists provider_id] && 0 != $provider_id && "" != $provider_id} {
    lappend criteria "prov.company_id = :provider_id"
}

if {[info exists sales_cc_id] && 0 != $sales_cc_id && "" != $sales_cc_id} {
    lappend criteria "cust.sales_office = :sales_cc_id"
}

if {[info exists production_cc_id] && 0 != $production_cc_id && "" != $production_cc_id} {
    lappend criteria "cust.production_hub = :production_cc_id"
}

if {[info exists invoicing_cc_id] && 0 != $invoicing_cc_id && "" != $invoicing_cc_id} {
    lappend criteria "cust.invoicing_department = :invoicing_cc_id"
}

if {[info exists internal_contact_id] && 0 != $internal_contact_id && "" != $internal_contact_id} {
    lappend criteria "cust.internal_contact_name = :internal_contact_id"
}


set where_clause [join $criteria " and\n	    "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#


set inner_sql "
select
	c.*,
	round((c.amount * im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric, 2) as amount_converted
from
	im_costs c
where
	c.cost_type_id = :cost_type_id
	and c.effective_date >= to_date(:start_date, 'YYYY-MM-DD')
	and c.effective_date < to_date(:end_date, 'YYYY-MM-DD')
	and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
"


set sql "
select
	c.cost_id,
	c.cost_name,
	c.customer_id,
	c.provider_id,
	c.cost_type_id,
	c.cost_status_id,

	to_char(c.effective_date, :date_format) as effective_date_formatted,
	to_char(c.effective_date, 'YYMM')::integer * customer_id as effective_month,
	cust.company_path as customer_nr,
	cust.company_name as customer_name,
	prov.company_path as provider_nr,
	prov.company_name as provider_name,

	c.amount_converted as amount,
	round(c.amount * c.vat) / 100 as vat_amount,
	c.amount_converted + round(c.amount * c.vat) / 100 as total,

	im_cost_center_code_from_id(cust.sales_office) as sales_cc,
	im_cost_center_code_from_id(cust.production_hub) as production_cc,
	im_cost_center_code_from_id(cust.invoicing_department) as invoicing_cc,
	cust.contawin_customer_code
from
	($inner_sql) c
	LEFT OUTER JOIN im_companies cust on (c.customer_id = cust.company_id)
	LEFT OUTER JOIN im_companies prov on (c.provider_id = prov.company_id)
where
	1 = 1
	$where_clause
order by
	cust.company_name
"

# Global header/footer
set header0 {"Cust" "Sales" "Prod" "Inv." "Effective Date" "Name" "Amount" "VAT" "Total" "Curr"}

set report_def [list \
    group_by customer_id \
    header {
	"\#colspan=10 <a href=$this_url&customer_id=$customer_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$company_url$customer_id>$customer_name</a></b>"
    } \
    content [list \
	    header {
		"$contawin_customer_code"
		"$sales_cc"
		"$production_cc"
		"$invoicing_cc"
		"<nobr>$effective_date_formatted</nobr>"
		"<nobr><a href=$invoice_url$cost_id>$cost_name</a></nobr>"
		"<nobr>$amount_pretty</nobr>"
		"<nobr>$vat_amount_pretty</nobr>"
                "<nobr>$total_pretty</nobr>"
		"<nobr>$default_currency</nobr>"
		""
	    } \
	    content {} \
    ] \
    footer {
	"" 
	""
	"" 
	"" 
	""
	""
	"<b>$amount_subtotal_pretty</b>" 
	"<b>$vat_subtotal_pretty</b>" 
	""
	"$default_currency"
    } \
]

# Global footer
set footer0 { }


set amount_subtotal 0
set vat_subtotal 0

#
# Subtotal Counters (per customer)
#
set amount_subtotal_counter [list \
	pretty_name "Amount" \
	var amount_subtotal \
	reset \$customer_id \
	expr "\$amount+0" \
]

set vat_subtotal_counter [list \
	pretty_name "VAT" \
	var vat_subtotal \
	reset \$customer_id \
	expr "\$vat_amount+0" \
]

set counters [list \
	$amount_subtotal_counter \
	$vat_subtotal_counter \
]


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 "Customer Only" 2 "All Details"} 
set cost_type_options {3700 "Customer Invoices" 3704 "Provider Bills"} 

# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

# Add the HTML select box to the head of the page
switch $output_format {
    html {
	ns_write "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	<td>
	<form>
		[export_form_vars customer_id]
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		  <td class=form-label>Level of Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Start Date</td>
		  <td class=form-widget>
		    <input type=textfield name=start_date value=$start_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>End Date</td>
		  <td class=form-widget>
		    <input type=textfield name=end_date value=$end_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Cost Type</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 cost_type_id $cost_type_options $cost_type_id ]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Sales Office</td>
		  <td class=form-widget>
		    [im_cost_center_select -include_empty 1 sales_cc_id $sales_cc_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Production Hub</td>
		  <td class=form-widget>
		    [im_cost_center_select -include_empty 1 production_cc_id $invoicing_cc_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Invoicing Office</td>
		  <td class=form-widget>
		    [im_cost_center_select -include_empty 1 invoicing_cc_id $invoicing_cc_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Internal Contact</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name "" -group_id [im_accounting_group_id] internal_contact_id $internal_contact_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Format</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		  <td class=form-label><nobr>Number Format</nobr></td>
		  <td class=form-widget>
		    [im_report_number_locale_select number_locale $number_locale]
		  </td>
		</tr>

		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>
	</form>
	</td>
	<td>
		<table cellspacing=2 width=90%>
		<tr><td>$help_text</td></tr>
		</table>
	</td>
	</tr>
	</table>
	<table border=0 cellspacing=1 cellpadding=1>\n"
    }
}

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

ns_log Notice "intranet-reporting-finance/finance-contawin: sql=\n$sql"

db_foreach sql $sql {

	set amount_pretty [im_report_format_number $amount $output_format $number_locale]
	set total_pretty [im_report_format_number $total $output_format $number_locale]
	set vat_amount_pretty [im_report_format_number $vat_amount $output_format $number_locale]

	im_report_display_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	
	im_report_update_counters -counters $counters
	
	set amount_subtotal_pretty [im_report_format_number $amount_subtotal $output_format $number_locale]
	set vat_subtotal_pretty [im_report_format_number $vat_subtotal $output_format $number_locale]

	set last_value_list [im_report_render_header \
	    -output_format $output_format \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	set footer_array_list [im_report_render_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]
}

im_report_display_footer \
    -output_format $output_format \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1

switch $output_format {
    html { ns_write "</table>\n[im_footer]\n" }
}
