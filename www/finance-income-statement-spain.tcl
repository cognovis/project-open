# /packages/intranet-reporting-finance/www/finance-income-statement-spain.tcl
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
    { year "" }
    { quarter "" }
    { profit_tax_percentage "" }
    { level_of_detail 3 }
    { output_format "html" }
    { number_locale "" }
    { customer_id:integer 0}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
# set current_user_id [ad_maybe_redirect_for_registration]
set current_user_id [ad_get_user_id]
set menu_label "reporting-finance-income-statement"

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


# ------------------------------------------------------------
# Set the default start and end date

set this_year [string range [ns_localsqltimestamp] 0 3]
set this_month [string range [ns_localsqltimestamp] 5 6]
regsub -all "0" $this_month "" this_month
set this_quarter [expr 1+int(($this_month-1) / 3)]

if {"" == $profit_tax_percentage} { set profit_tax_percentage 20 }
if {"" == $year} { set year $this_year }
if {"" == $quarter} { set quarter $this_quarter }
set next_year [expr $year+1]

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
set this_url [export_vars -base "/intranet-reporting-finance/finance-income-statement-spain" {year quarter} ]


# ------------------------------------------------------------
# Constants
#

set quarter_options {1 1T 2 2T 3 3T 4 4T}


# ------------------------------------------------------------
# Page Settings

set page_title "Income Statement"
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong>Income Statement:</strong><br>

This report provides a basic income statement to be used for 
quarterly financial reporting.

All financial items are considerted with effective_date 
between start date and end date.

<br>
Start Date is inclusive (document with effective date = Start Date
or later), while End Date is exclusive (documents earlier then 
End Date, exclucing End Date).
<br>
"

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
		  <td class=form-label><nobr>Year and Quarter&nbsp;</nobr></td>
		  <td class=form-widget>
		    <nobr>
		    <input type=text name=year value=$this_year size=4>
		    [im_select -translate_p 0 quarter $quarter_options $quarter]
		    </nobr>
		  </td>
		</tr>

		<tr>
		  <td class=form-label><nobr>Tax Percentage</nobr></td>
		  <td class=form-widget>
		    <input type=text name=profit_tax_percentage value=$profit_tax_percentage size=4>
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
	"
    }
}


# ------------------------------------------------------------
# Report definition

set report_def [list \
    group_by cost_type_id \
    header {
	"\#colspan=10 
	<b>$cost_type</b>"
    } \
        content [list \
            group_by customer_id \
            header { 
		"" 
		"<a href=$this_url&customer_id=$customer_id&level_of_detail=4 
		target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
		<b><a href=$company_url$customer_id>$customer_name</a></b>"
		"" 
		""
		""
		""
		""
		""
		""
		""
	    } \
	    content [list \
		    header {
			""
			"<nobr>$company_html</nobr>"
			"<nobr>$effective_date_formatted</nobr>"
			"<nobr>$paid_amount</nobr>"
			"<nobr><a href=$invoice_url$cost_id>$cost_name</a></nobr>"

			"<nobr>$invoice_amount_pretty</nobr>"
			"<nobr>$bill_amount_pretty</nobr>"
			"<nobr>$expense_amount_pretty</nobr>"
			"<nobr>$vat_amount_pretty</nobr>"
			"<nobr>$tax_amount_pretty</nobr>"
		    } \
		    content {} \
	    ] \
            footer {
		"&nbsp;"
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
    ] \
    footer {  
		""
		""
		"" 
		"<i>$paid_subtotal_pretty</i>"
		""
		"<i>$invoice_subtotal_pretty</i>" 
		"<i>$bill_subtotal_pretty</i>" 
		"<i>$expense_subtotal_pretty</i>"
		"<i>$vat_subtotal_pretty</i>"
		"<i>$tax_subtotal_pretty</i>"
    } \
]

set invoice_total_pretty 0
set bill_total_pretty 0
set expense_total_pretty 0
set vat_total_pretty 0
set tax_total_pretty 0

# Global header/footer
set header0 {"Cust" "Project" "Effective Date" "Paid" "Name" "Invoice" "Bill" "Expenses" "Vat" "Tax"}
set footer0 {
	"" 
	"" 
	"" 
	"" 
	"<br><b>Total:</b>" 
	"<br><b>$invoice_total_pretty</b>" 
	"<br><b>$bill_total_pretty</b>" 
	"<br><b>$expense_total_pretty</b>"
	"<br><b>$vat_total_pretty</b>"
	"<br><b>$tax_total_pretty</b>"
}

#
# Subtotal Counters (per project)
#
set paid_subtotal_counter [list \
        pretty_name "Paid Amount" \
        var paid_subtotal \
        reset \$cost_type_id \
        expr "\$paid_amount+0" \
]

set invoice_subtotal_counter [list \
        pretty_name "Invoice Amount" \
        var invoice_subtotal \
        reset \$cost_type_id \
        expr "\$invoice_amount+0" \
]

set bill_subtotal_counter [list \
        pretty_name "Bill Amount" \
        var bill_subtotal \
        reset \$cost_type_id \
        expr "\$bill_amount+0" \
]

set expense_subtotal_counter [list \
        pretty_name "Expence Amount" \
        var expense_subtotal \
        reset \$cost_type_id \
        expr "\$expense_amount+0" \
]

set vat_subtotal_counter [list \
        pretty_name "VAT Amount" \
        var vat_subtotal \
        reset \$cost_type_id \
        expr "\$vat_amount+0" \
]

set tax_subtotal_counter [list \
        pretty_name "Tax Amount" \
        var tax_subtotal \
        reset \$cost_type_id \
        expr "\$tax_amount+0" \
]

#
# Grand Total Counters
#
set paid_grand_total_counter [list \
        pretty_name "Paid Amount" \
        var paid_total \
        reset 0 \
        expr "\$paid_amount+0" \
]

set invoice_grand_total_counter [list \
        pretty_name "Invoice Amount" \
        var invoice_total \
        reset 0 \
        expr "\$invoice_amount+0" \
]

set bill_grand_total_counter [list \
        pretty_name "Bill Amount" \
        var bill_total \
        reset 0 \
        expr "\$bill_amount+0" \
]

set expense_grand_total_counter [list \
        pretty_name "Expense Amount" \
        var expense_total \
        reset 0 \
        expr "\$expense_amount+0" \
]

set vat_grand_total_counter [list \
        pretty_name "Vat Amount" \
        var vat_total \
        reset 0 \
        expr "\$vat_amount+0" \
]

set tax_grand_total_counter [list \
        pretty_name "Tax Amount" \
        var tax_total \
        reset 0 \
        expr "\$tax_amount+0" \
]




set counters [list \
	$paid_subtotal_counter \
	$invoice_subtotal_counter \
	$bill_subtotal_counter \
	$expense_subtotal_counter \
	$vat_subtotal_counter \
	$tax_subtotal_counter \
	$paid_grand_total_counter \
	$invoice_grand_total_counter \
	$bill_grand_total_counter \
	$expense_grand_total_counter \
	$vat_grand_total_counter \
	$tax_grand_total_counter \
]




# ------------------------------------------------------------
# Cummulative Report - Starting 1st of January
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
	c.vat,
	c.tax,
	round((c.paid_amount * 
	  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
	  , 2) as paid_amount_conv,
	c.paid_amount,
	c.paid_currency,
	round((c.amount * 
	  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
	  , 2) as amount_conv,
	c.amount,
	c.currency
from
	im_costs c
	LEFT OUTER JOIN acs_rels r on (c.cost_id = r.object_id_two)
where
	c.cost_type_id in (3700, 3704, 3720)
	and c.effective_date >= to_date(:start_date, 'YYYY-MM-DD')
	and c.effective_date < to_date(:end_date, 'YYYY-MM-DD')
	and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
"


set sql "
select
	c.*,
	to_char(c.effective_date, :date_format) as effective_date_formatted,
	to_char(c.effective_date, 'YYMM')::integer * customer_id as effective_month,
	CASE WHEN c.cost_type_id = 3700 THEN c.amount_conv END as invoice_amount,
	CASE WHEN c.cost_type_id = 3704 THEN c.amount_conv END as bill_amount,
	CASE WHEN c.cost_type_id = 3720 THEN c.amount_conv END as expense_amount,
	cust.company_path as customer_nr,
	cust.company_name as customer_name,
	prov.company_path as provider_nr,
	prov.company_name as provider_name,
	CASE
		WHEN c.cost_type_id in (3700) THEN c.amount_conv * vat / 100
		WHEN c.cost_type_id in (3704,3720,3720) THEN -c.amount_conv * vat / 100
		ELSE 0
	END as vat_amount,
	CASE
		WHEN c.cost_type_id in (3700) THEN c.amount_conv * tax / 100
		WHEN c.cost_type_id in (3704,3720,3720) THEN -c.amount_conv * tax / 100
		ELSE 0
	END as tax_amount,
	cust.company_id as customer_id,
	cust.company_name as customer_name,
	im_category_from_id(c.cost_type_id) as cost_type,
	e.external_company_name
from
	($inner_sql) c
	LEFT OUTER JOIN im_companies cust on (c.customer_id = cust.company_id)
	LEFT OUTER JOIN im_companies prov on (c.provider_id = prov.company_id)
	LEFT OUTER JOIN im_expenses e on (c.cost_id = e.expense_id)
where
	1 = 1
order by
	c.cost_type_id,
	c.customer_id, 
	c.provider_id
"



# ------------------------------------------------------------
# Start formatting the report body for the Nth Quarter
#

# Start- and end date
# In this first report we sum up only about the current quarter
switch $quarter {
    1 { 
	set start_date "$year-01-01"
	set end_date "$year-04-01" 
    }
    2 { 
	set start_date "$year-04-01"
	set end_date "$year-07-01" 
    }
    3 { 
	set start_date "$year-07-01"
	set end_date "$year-10-01" 
    }
    4 { 
	set start_date "$year-10-01"
	set end_date "$next_year-01-01" 
    }
    default { 
	ad_return_complaint 1 "Wrong quarter: '$quarter'" 
    }
}

ns_write "
	<br>
	<h1>Current Quarter Only ($start_date - $end_date)</h1>
	<table border=0 cellspacing=1 cellpadding=1>
"


# Reset counters
set bill_subtotal 0
set bill_total 0
set expense_subtotal 0
set expense_total 0
set invoice_subtotal 0
set invoice_total 0
set paid_subtotal 0
set paid_total 0
set tax_subtotal 0
set tax_total 0
set vat_subtotal 0
set vat_total 0

set invoice_total_pretty 0
set bill_total_pretty 0
set expense_total_pretty 0
set vat_total_pretty 0
set tax_total_pretty 0



im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

set total_year_irpf_soportado 0

db_foreach sql $sql {
    
    set invoice_amount_pretty [im_report_format_number $invoice_amount $output_format $number_locale]
    set bill_amount_pretty [im_report_format_number $bill_amount $output_format $number_locale]
    set expense_amount_pretty [im_report_format_number $expense_amount $output_format $number_locale]
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

    set paid_subtotal_pretty [im_report_format_number $paid_subtotal $output_format $number_locale]
    set invoice_subtotal_pretty [im_report_format_number $invoice_subtotal $output_format $number_locale]
    set bill_subtotal_pretty [im_report_format_number $bill_subtotal $output_format $number_locale]
    set expense_subtotal_pretty [im_report_format_number $expense_subtotal $output_format $number_locale]
    set tax_subtotal_pretty [im_report_format_number $tax_subtotal $output_format $number_locale]
    set vat_subtotal_pretty [im_report_format_number $vat_subtotal $output_format $number_locale]

    set paid_total_pretty [im_report_format_number $paid_total $output_format $number_locale]
    set invoice_total_pretty [im_report_format_number $invoice_total $output_format $number_locale]
    set bill_total_pretty [im_report_format_number $bill_total $output_format $number_locale]
    set expense_total_pretty [im_report_format_number $expense_total $output_format $number_locale]
    set tax_total_pretty [im_report_format_number $tax_total $output_format $number_locale]
    set vat_total_pretty [im_report_format_number $vat_total $output_format $number_locale]

    
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


ns_write "</table>\n"









# ------------------------------------------------------------
# Start formatting the report body for the entire year
#


# Start- and end date
# In this 2nd part we sum up over the entire year
switch $quarter {
    1 { 
	set start_date "$year-01-01"
	set end_date "$year-04-01" 
    }
    2 { 
	set start_date "$year-01-01"
	set end_date "$year-07-01" 
    }
    3 { 
	set start_date "$year-01-01"
	set end_date "$year-10-01" 
    }
    4 { 
	set start_date "$year-01-01"
	set end_date "$next_year-01-01" 
    }
    default { 
	ad_return_complaint 1 "Wrong quarter: '$quarter'" 
    }
}


ns_write "
	<br>
	<h1>Cummulative entire year ($start_date - $end_date)</h1>
	<table border=0 cellspacing=1 cellpadding=1>
"


# Reset counters
set bill_subtotal 0
set bill_total 0
set expense_subtotal 0
set expense_total 0
set invoice_subtotal 0
set invoice_total 0
set paid_subtotal 0
set paid_total 0
set tax_subtotal 0
set tax_total 0
set vat_subtotal 0
set vat_total 0

set invoice_total_pretty 0
set bill_total_pretty 0
set expense_total_pretty 0
set vat_total_pretty 0
set tax_total_pretty 0



im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

set total_year_irpf_soportado 0

db_foreach sql $sql {
    
    set invoice_amount_pretty [im_report_format_number $invoice_amount $output_format $number_locale]
    set bill_amount_pretty [im_report_format_number $bill_amount $output_format $number_locale]
    set expense_amount_pretty [im_report_format_number $expense_amount $output_format $number_locale]
    set vat_amount_pretty [im_report_format_number $vat_amount $output_format $number_locale]
    set tax_amount_pretty [im_report_format_number $tax_amount $output_format $number_locale]
    
    if {$cost_type_id == [im_cost_type_invoice]} {
	if {"" == $tax_amount} { set tax_amount 0 }
	set total_year_irpf_soportado [expr $total_year_irpf_soportado + $tax_amount]
    }

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

    set paid_subtotal_pretty [im_report_format_number $paid_subtotal $output_format $number_locale]
    set invoice_subtotal_pretty [im_report_format_number $invoice_subtotal $output_format $number_locale]
    set bill_subtotal_pretty [im_report_format_number $bill_subtotal $output_format $number_locale]
    set expense_subtotal_pretty [im_report_format_number $expense_subtotal $output_format $number_locale]
    set tax_subtotal_pretty [im_report_format_number $tax_subtotal $output_format $number_locale]
    set vat_subtotal_pretty [im_report_format_number $vat_subtotal $output_format $number_locale]

    set paid_total_pretty [im_report_format_number $paid_total $output_format $number_locale]
    set invoice_total_pretty [im_report_format_number $invoice_total $output_format $number_locale]
    set bill_total_pretty [im_report_format_number $bill_total $output_format $number_locale]
    set expense_total_pretty [im_report_format_number $expense_total $output_format $number_locale]
    set tax_total_pretty [im_report_format_number $tax_total $output_format $number_locale]
    set vat_total_pretty [im_report_format_number $vat_total $output_format $number_locale]

    
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



# Extract relevant variables

set total_year_earnings $invoice_total
set total_year_expenses [expr $bill_total + $expense_total]
set total_year_profit [expr $invoice_total - $bill_total - $expense_total]
set total_year_tax [expr $total_year_profit * $profit_tax_percentage]











switch $output_format {
    html { 
	ns_write "</table>\n" 

	ns_write "
		<table cellspacing=2 cellpadding=2>
		<tr class=rowtitle>
			<td colspan=3 class=rowtitle>Formulario 130</tr>
		</tr>
		<tr class=roweven>
			<td>Total Year Earnings</td>
			<td>Casilla 130/01</td>
			<td>$total_year_earnings</td>
		</tr>
		<tr class=rowodd>
			<td>Total Year Expenses</td>
			<td>Casilla 130/02</td>
			<td>$total_year_expenses</td>
		</tr>
		<tr class=roweven>
			<td>Total Year Profit</td>
			<td>Casilla 130/03</td>
			<td>$total_year_profit</td>
		</tr>
		<tr class=rowodd>
			<td>Total Year Tax (Profit * $profit_tax_percentage% Tax)</td>
			<td>Casilla 130/04</td>
			<td>$total_year_tax</td>
		</tr>
		<tr class=roweven>
			<td>Total Year IRPF Soportado</td>
			<td>Casilla 130/06</td>
			<td>$total_year_irpf_soportado</td>
		</tr>
		<tr class=rowodd>
			<td colspan=3>&nbsp;</tr>
		</tr>
		</table>
	"

	ns_write [im_footer]

    }
}




