# /packages/intranet-reporting-finance/www/finance-vat.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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
    { level_of_detail 4 }
    { output_format "html" }
    { number_locale "" }
    { customer_id:integer 0}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [ad_maybe_redirect_for_registration]

# Same label as income statement...
set menu_label "reporting-finance-vat"

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

set read_p "t"

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }

set company_url "/intranet/companies/view?company_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-finance/finance-income-statement" {start_date end_date} ]


# Deal with invoices related to multiple projects
im_invoices_check_for_multi_project_invoices


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006 2007}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {2 "Quarter and Cost Type" 3 "Quarter, Cost Type and VAT Type" 4 "All Details"} 



# ------------------------------------------------------------
# Argument Checking

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
# Page Settings

set page_title "VAT Report"
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong>VAT Report:</strong><br>
This reports lists financial items by VAT type.
<br>
Start Date is inclusive (document with effective date = Start Date
or later), while End Date is exclusive (documents earlier then 
End Date, exclucing End Date).
<br>
"



# ------------------------------------------------------------
# Set the default start and end date

set days_in_past 7

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
if {$level_of_detail > 4} { set level_of_detail 4 }


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


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {0 != $customer_id} {
    lappend criteria "cust.company_id = :customer_id"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}



# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#


set inner_sql "
select distinct
	c.cost_id,
	c.cost_type_id,
	c.cost_status_id,
	c.cost_nr,
	c.cost_name,
	c.effective_date,
	c.customer_id,
	c.provider_id,
	coalesce(c.vat, 0) as vat,
	to_char(c.vat, '00') as vat_pretty,
	c.tax,
	round((c.amount * 
	  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
	  , 2) as amount_conv,
	c.amount,
	c.currency,
	coalesce(im_category_from_id(c.vat_type_id), im_cost_vat_type_from_cost_id(c.cost_id)) as vat_type,
	im_cost_vat_type_from_cost_id(c.cost_id) as vat_type_calculated,
	(select vat_number from im_companies cust where cust.company_id = c.customer_id) as customer_vat_number,
	(select vat_number from im_companies prov where prov.company_id = c.provider_id) as provider_vat_number,
	(select external_company_vat_number from im_expenses exp where exp.expense_id = c.cost_id) as expense_vat_number
from
	im_costs c
	LEFT OUTER JOIN acs_rels r on (c.cost_id = r.object_id_two)
where
	c.cost_type_id in (3700,3704,3720,3730,3732)
	and c.effective_date >= to_date(:start_date, 'YYYY-MM-DD')
	and c.effective_date < to_date(:end_date, 'YYYY-MM-DD')
"

set expense_select ", '' as external_company_name"
set expense_from ""
set expense_where ""
if {[im_table_exists im_expenses]} {
    set expense_select ", e.external_company_name"
    set expense_from "LEFT OUTER JOIN im_expenses e on (c.cost_id = e.expense_id)"
}

set sql "
select
	c.*,
	to_char(c.effective_date, :date_format) as effective_date_formatted,
	to_char(c.effective_date, 'YYMM')::integer * customer_id as effective_month,
	to_char(c.effective_date, 'Q')::integer as effective_quarter,
	to_char(c.effective_date, 'YYYY-Q') as effective_year_quarter,
	c.amount_conv as cost_item_amount,
	cust.company_path as customer_nr,
	cust.company_name as customer_name,
	prov.company_path as provider_nr,
	prov.company_name as provider_name,
	to_char(c.effective_date, 'YYYYQ')::numeric * 
		(-3699+cost_type_id::numeric) * 
		(1+c.vat::numeric) * 
		ascii(vat_type)::numeric 
	as quarter_cost_type_vat_type,
	round(CASE
		WHEN c.cost_type_id in (3700) THEN c.amount_conv * vat / 100
		WHEN c.cost_type_id in (3704,3720,3720) THEN -c.amount_conv * vat / 100
		ELSE 0
	END,2) as vat_amount,
	round(CASE
		WHEN c.cost_type_id in (3700) THEN c.amount_conv * tax / 100
		WHEN c.cost_type_id in (3704,3720,3720) THEN -c.amount_conv * tax / 100
		ELSE 0
	END,2) as tax_amount,
	cust.company_id as customer_id,
	cust.company_name as customer_name,
	im_category_from_id(c.cost_type_id) as cost_type,
	vat_type || im_category_from_id(c.cost_type_id) as vat_type_cost_type
	$expense_select
from
	($inner_sql) c
	LEFT OUTER JOIN im_companies cust on (c.customer_id = cust.company_id)
	LEFT OUTER JOIN im_companies prov on (c.provider_id = prov.company_id)
	$expense_from
where
	1 = 1
	$where_clause
	$expense_where
order by
	effective_year_quarter,
	cost_type_id,
	vat_type,
	c.customer_id, 
	c.provider_id
"

set report_def [list \
    group_by effective_year_quarter \
    header {
	"\#colspan=11 Quarter $effective_year_quarter"
    } \
        content [list \
            group_by cost_type \
            header { 
		""
		"\#colspan=11 <b>$cost_type</b>"
	    } \
	    content [list \
	            group_by vat_type_cost_type \
	            header { 
			""
			""
			"\#colspan=10 $vat_type"
		    } \
		    content [list \
			    header {
				""
				"$quarter_cost_type_vat_type"
				""
				"<nobr>$company_html</nobr>"
				"<nobr>$vat_number</nobr>"
				"<nobr>$effective_date_formatted</nobr>"
				"<nobr><a href=$invoice_url$cost_id>$cost_name</a></nobr>"
				"<nobr>$cost_item_amount_pretty</nobr>"
				"<nobr>$vat_amount_pretty</nobr>"
				"<nobr>$tax_amount_pretty</nobr>"
			    } \
			    content {} \
		    ] \
	            footer {
			""
			"$quarter_cost_type_vat_type"
			""
	                ""
	                ""
	                ""
	                ""
	                "<i>$cost_item_vattype_subtotal_pretty</i>"
	                "<i>$vat_vattype_subtotal_pretty</i>"
	                "<i>$tax_vattype_subtotal_pretty</i>"
	            } \
	    ] \
	footer {} \
    ] \
    footer {  
		""
		""
		""
		""
		""
		"" 
		""
		""
		""
		""
    } \
]

set cost_item_vattype_subtotal 0
set tax_vattype_subtotal 0
set vat_vattype_subtotal 0

# Global header/footer
set header0 {"Q" "Cost<br>Type" "VAT<br>Type" "Customer" "VAT<br>Number" "Effective<br>Date" "Name" "Amount" "Vat" "Tax"}
set footer0 {
	"" 
	"" 
	"" 
	"" 
	"" 
	"" 
	""
	""
	""
	""
}



#
# Customer Counters (per customer)
#

set cost_item_vattype_subtotal_counter [list \
        pretty_name "Invoice Amount" \
        var cost_item_vattype_subtotal \
        reset \$quarter_cost_type_vat_type \
        expr "\$cost_item_amount+0" \
				      ]

set vat_vattype_subtotal_counter [list \
        pretty_name "VAT Amount" \
        var vat_vattype_subtotal \
        reset \$quarter_cost_type_vat_type \
        expr "\$vat_amount+0" \
				  ]

set tax_vattype_subtotal_counter [list \
        pretty_name "Tax Amount" \
        var tax_vattype_subtotal \
        reset \$quarter_cost_type_vat_type \
        expr "\$tax_amount+0" \
				  ]

set counters [list \
	$cost_item_vattype_subtotal_counter \
	$vat_vattype_subtotal_counter \
	$tax_vattype_subtotal_counter \
]


# ------------------------------------------------------------
# Start formatting the page header
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
                  <td class=form-label>Format</td>
                  <td class=form-widget>
                    [im_report_output_format_select output_format "" $output_format]
                  </td>
                </tr>
                <tr>
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


# ------------------------------------------------------------
# Start formatting the report body
#

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

ns_log Notice "intranet-reporting-finance/finance-income-statement: sql=\n$sql"

db_foreach sql $sql {

    if {"" == $quarter_cost_type_vat_type} { 
	set quarter_cost_type_vat_type $cost_id
    }

    set invoice_or_quote_p [expr $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_quote] || $cost_type_id == [im_cost_type_delivery_note] || $cost_type_id == [im_cost_type_interco_quote] || $cost_type_id == [im_cost_type_interco_invoice]]
    if {$invoice_or_quote_p} {
	set vat_number $customer_vat_number
    } else {
	set vat_number $provider_vat_number
    }
    if {"" != $expense_vat_number} { set vat_number $expense_vat_number }

    set cost_item_amount_pretty [im_report_format_number $cost_item_amount $output_format $number_locale]
    set vat_amount_pretty [im_report_format_number $vat_amount $output_format $number_locale]
    set tax_amount_pretty [im_report_format_number $tax_amount $output_format $number_locale]
    
    if {"" == $customer_id} {
	set customer_id 0
	set customer_name "No Customer"
    }
    
    # Get the "interesting" company (the one that is NOT "internal")
    set company_html "<a href=$company_url$customer_id>$customer_name</a>"
    if {$customer_id == [im_company_internal]} {
	set company_html "<a href=$company_url$provider_id>$provider_name</a>"
    }
    if {$cost_type_id == [im_cost_type_expense_item]} {
	set company_html $external_company_name
    }
    
    im_report_display_footer \
	-output_format $output_format \
	-group_def $report_def \
	-footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list \
	-level_of_detail $level_of_detail \
	-row_class $class \
	-cell_class $class

    # Update Counters and calculate pretty counter values
    im_report_update_counters -counters $counters

    set cost_item_vattype_subtotal_pretty [im_report_format_number $cost_item_vattype_subtotal $output_format $number_locale]
    set tax_vattype_subtotal_pretty [im_report_format_number $tax_vattype_subtotal $output_format $number_locale]
    set vat_vattype_subtotal_pretty [im_report_format_number $vat_vattype_subtotal $output_format $number_locale]
    
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
    html { 
	ns_write "</table>\n[im_footer]\n" 
    }
}
