# /packages/intranet-reporting/www/finance-projects-documents.tcl
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
    {start_date "" }
    {end_date "" }
    {level_of_detail:integer 3 }
    {output_format "html" }
    {customer_type_id:integer 0 }
    {sales_rep_id:integer 0 }
    {project_id:integer 0 }
    {customer_id:integer 0 }
    {project_status_ids:multiple "76 78 79" }
    location:array,optional
    field:array,optional    
    {custom_fields_p 0}
    {max_col 3}
    {max_fields 5}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-finance-projects-documents"

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


if {!$custom_fields_p} {
    set max_col 0
    set max_fields 0
    set custom_fields_checked ""
} else {
    set custom_fields_checked "checked"
}

# Deal with multiple projects per invoice
im_invoices_check_for_multi_project_invoices


# ------------------------------------------------------------
# Page Settings

set page_title "Projects and Financial Documents"
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong><nobr>$page_title</nobr></strong><br>

The purpose of this report is to determine the profitability of
the projects that end (end_date) in the time period between StartDate and End Date
by showing the relationship between quotes and purchase orders
(an approximation of the gross margin).

This selection is meant to provide a reasonable approximation 
for 'revenues in this period' if there are many small projects, 
as it is the case in translation agencies.<br>

The report shows all financial documents for the selected projects,
even if their creation and due dates are outside of the period 
between Start Date and End Date.
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set days_in_past 7

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

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


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/finance-projects-documents" {start_date end_date} ]
set current_url [im_url_with_query]

# ------------------------------------------------------------
# Options
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 "Customer Only" 2 "Customer+MainP" 3 "Customer+Main+SubP" 4 "All Details"} 

# Get the list of everybody who once created in invoice
set sales_rep_options [db_list_of_lists sales_reps "
    select * from (
	select distinct
		im_name_from_user_id(creation_user) as user_name,
		creation_user as user_id
	from
		acs_objects o,
		im_costs c,
		im_invoices i
	where
		i.invoice_id = c.cost_id
		and c.cost_id = o.object_id
   ) t
   order by user_name
"]
set sales_rep_options [linsert $sales_rep_options 0 [list "" 0]]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]


if {0 != $sales_rep_id} {
    lappend criteria "c.creation_user = :sales_rep_id"
}

if {0 != $customer_id && "" != $customer_id} {
    lappend criteria "pcust.company_id = :customer_id"
}

if {"" != $customer_type_id && 0 != $customer_type_id} {
    lappend criteria "pcust.company_type_id in ([join [im_sub_categories $customer_type_id] ","])"
}

# Select project & subprojects
if {0 != $project_id && "" != $project_id} {
    lappend criteria "p.project_id in (
	select
		p.project_id
	from
		im_projects p,
		im_projects parent_p
	where
		parent_p.project_id = :project_id
		and p.tree_sortkey 
			between parent_p.tree_sortkey 
			and tree_right(parent_p.tree_sortkey)
		and p.project_status_id not in ([im_project_status_deleted])
    )"
}

if {[llength $project_status_ids] > 0} {
    lappend criteria "p.project_status_id in ([join $project_status_ids ","])"
} 

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set inner_sql "
	select
		c.cost_id,
		c.cost_type_id,
		c.cost_status_id,
		c.cost_nr,
		c.cost_name,
		c.effective_date,
		c.customer_id,
		c.provider_id,
		round((c.paid_amount * 
		  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
		  , 2) as paid_amount_converted,
		c.paid_amount,
		c.paid_currency,
		round((c.amount * 
		  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
		  , 2) as amount_converted,
		c.amount,
		c.currency,
		c.project_project_id,
		c.main_project_sortkey,
		o.creation_user
	from
		acs_objects o,
		(select distinct
			p.project_id as project_project_id,
			tree_ancestor_key(p.tree_sortkey, 1) as main_project_sortkey,
			c.*
		 from
			(select	project_id,
				tree_sortkey
			 from	im_projects p
			 where	p.end_date >= to_date(:start_date, 'YYYY-MM-DD')
				and p.end_date < to_date(:end_date, 'YYYY-MM-DD')
				and p.end_date::date < to_date(:end_date, 'YYYY-MM-DD')
				and p.project_status_id not in ([im_project_status_deleted])
			) p	 
			LEFT OUTER JOIN acs_rels r 
				ON (p.project_id = r.object_id_one)
			LEFT OUTER JOIN im_costs c 
				ON (c.cost_id = r.object_id_two OR c.project_id = p.project_id)
		) c
	where
		c.cost_id = o.object_id
		and (
			c.cost_type_id is null 
			OR c.cost_type_id in (3700, 3702, 3704, 3706, 3718, 3722, 3724, null)
		)
"


set sql "
select
	c.*,
	pcust.*,
	p.*,
	c.project_project_id as project_id,
	to_char(c.effective_date, :date_format) as effective_date_formatted,
	to_char(c.effective_date, 'YYMM')::integer * customer_id as effective_month,
	c.creation_user as sales_rep_id,
	im_name_from_user_id(c.creation_user) as sales_rep_name,
	cust.company_path as customer_nr,
	cust.company_name as customer_name,
	prov.company_path as provider_nr,
	prov.company_name as provider_name,

	mainp.project_id as main_project_id,
	mainp.project_nr as main_project_nr,
	mainp.project_name as main_project_name,

	CASE WHEN c.cost_type_id = 3700 THEN c.amount_converted END as invoice_amount,
	CASE WHEN c.cost_type_id = 3702 THEN c.amount_converted END as quote_amount,
	CASE WHEN c.cost_type_id = 3704 THEN c.amount_converted END as bill_amount,
	CASE WHEN c.cost_type_id = 3706 THEN c.amount_converted END as po_amount,
	CASE WHEN c.cost_type_id = 3718 THEN c.amount_converted END as timesheet_amount,
	CASE WHEN c.cost_type_id = 3722 THEN c.amount_converted END as expense_amount,
	CASE WHEN c.cost_type_id = 3724 THEN c.amount_converted END as delnote_amount,

	CASE WHEN c.cost_type_id = 3700 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as invoice_amount_pretty,
	CASE WHEN c.cost_type_id = 3702 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as quote_amount_pretty,
	CASE WHEN c.cost_type_id = 3704 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as bill_amount_pretty,
	CASE WHEN c.cost_type_id = 3706 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as po_amount_pretty,
	CASE WHEN c.cost_type_id = 3718 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as timesheet_amount_pretty,
	CASE WHEN c.cost_type_id = 3722 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as expense_amount_pretty,
	CASE WHEN c.cost_type_id = 3724 THEN to_char(c.amount, :cur_format) || ' ' || c.currency 
	END as delnote_amount_pretty,

	to_char(c.paid_amount, :cur_format) || ' ' || c.paid_currency as paid_amount_pretty,
	p.project_name,
	p.project_nr,
	p.end_date::date as project_end_date,
	pcust.company_id as project_customer_id,
	pcust.company_name as project_customer_name,
	im_category_from_id(pcust.company_status_id) as project_customer_status,
	im_category_from_id(pcust.company_type_id) as project_customer_type,
	'<a href=/intranet/users/view?user_id=' || pcust.manager_id || '>' || 
		im_name_from_user_id(pcust.manager_id) || '</a>' as project_customer_manager_link,
	im_category_from_id(p.project_status_id) as project_status,
	im_category_from_id(p.project_type_id) as project_type,
	trunc(p.percent_completed::numeric, 2) as percent_completed_formatted,
	'<a href=/intranet/users/view?user_id=' || p.project_lead_id || '>' || 
		im_name_from_user_id(p.project_lead_id) || '</a>' as project_lead_link,
	to_char(p.project_budget, :cur_format) || ' ' || p.project_budget_currency as project_budget_formatted,
	to_char(p.end_date, :date_format) as end_date_formatted,
	to_char(p.start_date, :date_format) as start_date_formatted,
	'<a href=/intranet/users/view?user_id=' || p.company_contact_id || '>' || 
		im_name_from_user_id(p.company_contact_id) || '</a>' as company_contact_link,
	im_category_from_id(p.source_language_id) as source_language,
	im_category_from_id(p.subject_area_id) as subject_area
from
	($inner_sql) c
	LEFT OUTER JOIN im_projects p on (c.project_project_id = p.project_id)
	LEFT OUTER JOIN im_companies cust on (c.customer_id = cust.company_id)
	LEFT OUTER JOIN im_companies prov on (c.provider_id = prov.company_id)
	LEFT OUTER JOIN im_companies pcust on (p.company_id = pcust.company_id)
	LEFT OUTER JOIN im_projects mainp on (c.main_project_sortkey = mainp.tree_sortkey)
where
	1 = 1
	$where_clause
order by
	pcust.company_name,
	mainp.project_name,
	p.project_name
"


# -----------------------------------------------------
# Cost-Header - The most detailed structure

set cost_header [list \
	"" \
	"" \
	"" \
	"<a href=\$invoice_url\$cost_id>\$cost_name</a>" \
]

# Lookup the position and add the field for the given position
for {set i 1} {$i <= $max_col} {incr i} {
    set cont ""
    set pos [lsearch [array get location] "cost$i"]
    if {$pos > -1} {
	set row [lindex [array get location] [expr $pos-1]]
	set cont "<nobr>\$$field($row)</nobr>"
    }
    lappend cost_header $cont
}

set cost_header [concat $cost_header [list \
	"<nobr><a href=\$user_url\$sales_rep_id>\$sales_rep_name</a></nobr>" \
	"<nobr>\$invoice_amount_pretty</nobr>" \
	"<nobr>\$delnote_amount_pretty</nobr>" \
	"<nobr>\$quote_amount_pretty</nobr>" \
	"<nobr>\$bill_amount_pretty</nobr>" \
	"<nobr>\$po_amount_pretty</nobr>" \
	"<nobr>\$expense_amount_pretty</nobr>" \
	"<nobr>\$timesheet_amount_pretty</nobr>" \
	"" \
	"" \
	"" \
]]


# -----------------------------------------------------
# Project-Footer - The middle structure

set project_footer {
	"" 
	"" 
	"<nobr><a href=$this_url&project_id=$project_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a>
	<b><a href=$project_url$project_id>$project_nr</nobr></a></b>"
	"<b><a href=$project_url$project_id><nobr>$project_name</nobr></a></b>"
}

# Lookup the position and add the field for the given position
for {set i 1} {$i <= $max_col} {incr i} {
    set cont ""
    set pos [lsearch [array get location] "proj$i"]
    if {$pos > -1} {
	set row [lindex [array get location] [expr $pos-1]]
	set cont "<nobr>\$$field($row)</nobr>"
    }
    lappend project_footer $cont
}

set project_footer [concat $project_footer [list \
	"" \
	"<nobr><i>\$invoice_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$delnote_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$quote_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$bill_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$po_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$expense_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$timesheet_subsubtotal \$default_currency</i></nobr>" \
	"<nobr><i>\$po_per_quote_perc_subsubtotal</i></nobr>" \
	"<nobr><i>\$gross_profit_subsubtotal</i></nobr>" \
	"<nobr><i>\$wip_subsubtotal</i></nobr>" \
]]


# -----------------------------------------------------
# Main-Project-Footer - The middle structure

set main_project_header {
	"" 
	"\#colspan=14 <nobr><a href=$this_url&main_project_id=$main_project_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a>
	<b><a href=$project_url$main_project_id>$main_project_nr</nobr></a></b>
	<b><a href=$project_url$main_project_id><nobr>$main_project_name</nobr></a></b>"
}

# Lookup the position and add the field for the given position
for {set i 1} {$i <= $max_col} {incr i} {
    set cont ""
    set pos [lsearch [array get location] "proj$i"]
    if {$pos > -1} {
	set row [lindex [array get location] [expr $pos-1]]
	set cont "<nobr>\$$field($row)</nobr>"
    }
    lappend main_project_header $cont
}

set main_project_header [concat $main_project_header [list \
	"" \
]]


# -----------------------------------------------------
# Project-Customer Footer

set project_customer_footer { 
	"" 
	"" 
	""
	""
}

# Lookup the position and add the field for the given position
for {set i 1} {$i <= $max_col} {incr i} {
    set cont ""
    set pos [lsearch [array get location] "cust$i"]
    if {$pos > -1} {
	set row [lindex [array get location] [expr $pos-1]]
	set cont "<nobr>\$$field($row)</nobr>"
    }
    lappend project_customer_footer $cont
}

set project_customer_footer [concat $project_customer_footer [list \
	"" \
	"<b>\$invoice_subtotal \$default_currency</b>" \
	"<b>\$delnote_subtotal \$default_currency</b>" \
	"<b>\$quote_subtotal \$default_currency</b>" \
	"<b>\$bill_subtotal \$default_currency</b>" \
	"<b>\$po_subtotal \$default_currency</b>" \
	"<b>\$expense_subtotal \$default_currency</b>" \
	"<b>\$timesheet_subtotal \$default_currency</b>" \
	"<b>\$po_per_quote_perc_subtotal</b>" \
	"<b>\$gross_profit_subtotal</b>" \
	"<b>\$wip_subtotal</b>" \
]]


set report_def [list \
    group_by project_customer_id \
    header {
	"\#colspan=14 <a href=$this_url&customer_id=$project_customer_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$company_url$project_customer_id>$project_customer_name</a></b>"
    } \
    content [list \
            group_by main_project_id \
            header $main_project_header \
            content [list \
	            group_by project_id \
	            header { } \
		    content [list \
			    header $cost_header \
			    content {} \
		    ] \
	            footer $project_footer \
	        ] \
	    footer { } \
    ] \
    footer $project_customer_footer \
]

# Global header/footer
set header0 [list "Cust" "MainP" "Project" "Name"]
for {set i 1} {$i <= $max_col} {incr i} { lappend header0 "<nobr>Col #$i</nobr>" }
set header0 [concat $header0 [list "Sales Rep" "Invoice" "Delnote" "Quote" "Bill" "PO" "Expense" "Timesheet" "PO/Quote" "Gross Profit" "WIP"]]

set footer0 {
	"" 
	"" 
	""
	""
}

# Add empty cols spacers
for {set i 1} {$i <= $max_col} {incr i} { lappend footer0 "" }

set footer0 [concat $footer0 {
	"<br><b><i>Total:</i></b>" 
	"<br><b><i>$invoice_total $default_currency</i></b>" 
	"<br><b><i>$delnote_total $default_currency</i></b>" 
	"<br><b><i>$quote_total $default_currency</i></b>" 
	"<br><b><i>$bill_total $default_currency</i></b>" 
	"<br><b><i>$po_total $default_currency</i></b>"
	"<br><b><i>$expense_total $default_currency</i></b>"
	"<br><b><i>$timesheet_total $default_currency</i></b>"
	"<br><b><i>$po_per_quote_perc_total</i></b>"
	"<br><b><i>$gross_profit_total</i></b>"
	"<br><b><i>$wip_total</i></b>"
}]


#
# SubSubtotal Counters (per project)
#
set invoice_subsubtotal_counter [list pretty_name "Invoice Amount" var invoice_subsubtotal reset \$project_id expr "\$invoice_amount+0"]
set delnote_subsubtotal_counter [list pretty_name "Delnote Amount" var delnote_subsubtotal reset \$project_id expr "\$delnote_amount+0"]
set quote_subsubtotal_counter [list pretty_name "Quote Amount" var quote_subsubtotal reset \$project_id expr "\$quote_amount+0"]
set bill_subsubtotal_counter [list pretty_name "Bill Amount" var bill_subsubtotal reset \$project_id expr "\$bill_amount+0"]
set po_subsubtotal_counter [list pretty_name "Po Amount" var po_subsubtotal reset \$project_id expr "\$po_amount+0"]
set expense_subsubtotal_counter [list pretty_name "Expense Amount" var expense_subsubtotal reset \$project_id expr "\$expense_amount+0"]
set timesheet_subsubtotal_counter [list pretty_name "Timesheet Amount" var timesheet_subsubtotal reset \$project_id expr "\$timesheet_amount+0"]


#
# SubTotal Counters (per customer)
#
set invoice_subtotal_counter [list pretty_name "Invoice Amount" var invoice_subtotal reset \$project_customer_id expr "\$invoice_amount+0"]
set delnote_subtotal_counter [list pretty_name "Delnote Amount" var delnote_subtotal reset \$project_customer_id expr "\$delnote_amount+0"]
set quote_subtotal_counter [list pretty_name "Quote Amount" var quote_subtotal reset \$project_customer_id expr "\$quote_amount+0"]
set bill_subtotal_counter [list pretty_name "Bill Amount" var bill_subtotal reset \$project_customer_id expr "\$bill_amount+0"]
set po_subtotal_counter [list pretty_name "Po Amount" var po_subtotal reset \$project_customer_id expr "\$po_amount+0"]
set expense_subtotal_counter [list pretty_name "Expense Amount" var expense_subtotal reset \$project_customer_id expr "\$expense_amount+0"]
set timesheet_subtotal_counter [list pretty_name "Timesheet Amount" var timesheet_subtotal reset \$project_customer_id expr "\$timesheet_amount+0"]

#
# GrandTotal Counters (everything)
#
set invoice_total_counter [list pretty_name "Invoice Amount" var invoice_total reset 0 expr "\$invoice_amount+0"]
set delnote_total_counter [list pretty_name "Delnote Amount" var delnote_total reset 0 expr "\$delnote_amount+0"]
set quote_total_counter [list pretty_name "Quote Amount" var quote_total reset 0 expr "\$quote_amount+0"]
set bill_total_counter [list pretty_name "Bill Amount" var bill_total reset 0 expr "\$bill_amount+0"]
set po_total_counter [list pretty_name "Po Amount" var po_total reset 0 expr "\$po_amount+0"]
set expense_total_counter [list pretty_name "Expense Amount" var expense_total reset 0 expr "\$expense_amount+0"]
set timesheet_total_counter [list pretty_name "Timesheet Amount" var timesheet_total reset 0 expr "\$timesheet_amount+0"]


set counters [list \
	$invoice_subsubtotal_counter \
	$delnote_subsubtotal_counter \
	$quote_subsubtotal_counter \
	$bill_subsubtotal_counter \
	$po_subsubtotal_counter \
	$expense_subsubtotal_counter \
	$timesheet_subsubtotal_counter \
	$invoice_subtotal_counter \
	$delnote_subtotal_counter \
	$quote_subtotal_counter \
	$bill_subtotal_counter \
	$po_subtotal_counter \
	$expense_subtotal_counter \
	$timesheet_subtotal_counter \
	$invoice_total_counter \
	$delnote_total_counter \
	$quote_total_counter \
	$bill_total_counter \
	$po_total_counter \
	$expense_total_counter \
	$timesheet_total_counter \
]


# ------------------------------------------------------------
# Field Table - Allow to add fields

set field_options {
	"" ""
	project_customer_status "Company - Company Status"
	project_customer_type "Company - Company Type"
	project_customer_manager_link "Company - Key Account"
}
set field_options [concat $field_options [im_dynfield_object_attributes_for_select -object_type "im_company"]]

set field_options [concat $field_options {
	project_status "Project - Project Status"
	project_type "Project - Project Type"
	project_lead_link "Project - Project Manager"
	project_budget_formatted "Project - Project Budget"
	project_budget_hours "Project - Project Budget Hours"
	percent_completed_formatted "Project - Percent Completed"
	end_date_formatted "Project - Start Date"
	start_date_formatted "Project - End Date"
	company_contact_link "Project - Customer Contact"
	company_project_nr "Project - Customer's Project Nr"
	source_language "Project - Source Language"
	subject_area "Project - Subject Area"	
	final_company "Project - Final Company"
	reported_hours_cache "Project - Reported Hours"
	cost_quotes_cache "Project - Quotes"
	cost_invoices_cache "Project - Invoices"
	cost_purchase_orders_cache "Project - Purchase Orders"
	cost_bills_cache "Project - Provider Bills"
	cost_timesheet_logged_cache "Project - Timesheet Costs"
	cost_expense_logged_cache "Project - Exenses"
	cost_delivery_notes_cache "Project - Delivery Notes"
}]
set field_options [concat $field_options [im_dynfield_object_attributes_for_select -object_type "im_project"]]


set location_options {"" ""}
for {set col 1} {$col <= $max_col} {incr col} {
	lappend location_options "cust$col"
	lappend location_options "Customer Group - Col \#$col"
}
for {set col 1} {$col <= $max_col} {incr col} {
	lappend location_options "proj$col"
	lappend location_options "Project Group - Col \#$col"
}
for {set col 1} {$col <= $max_col} {incr col} {
	lappend location_options "cost$col"
	lappend location_options "Cost Group - Col \#$col"
}


set field_table "<table cellspacing=1 cellpadding=1>"
append field_table "
        <tr class=rowtitle><td class=rowtitle colspan=2 align=center>Additional Custom Fields</td></tr>
        <tr class=rowtitle>
	    <td class=rowtitle align=center>Field</td>
	    <td class=rowtitle align=center>Location</td>
	</tr>
"

for {set row 1} {$row <= $max_fields} {incr row} {
    if {![info exists field($row)]} { set field($row) "" }
    if {![info exists location($row)]} { set location($row) ""}
    append field_table "
	<tr>
	<td class=form-label>[im_select -translate_p 0 field.$row $field_options $field($row)]</td>
	<td class=form-widget>[im_select -translate_p 0 location.$row $location_options $location($row)]</td>
	</tr>
    "
}

append field_table "
    <tr>
	<td class=form-label>&nbsp;</td>
	<td class=form-widget><input type=submit value=Submit></td>
    </tr>
"

append field_table "
    <tr>
	<td class=form-label>Max Custom Fields</td>
	<td class=form-widget><input type=text name=max_fields value=$max_fields size=3></td>
    </tr>
"
append field_table "
    <tr>
	<td class=form-label>Additional Columns</td>
	<td class=form-widget><input type=text name=max_col value=$max_col size=3></td>
    </tr>
"

append field_table "</table>\n"


if {!$custom_fields_p} { set field_table "" }

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

	<form>

	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	<td>
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
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
	          <td class=form-label>Project Status</td>
	          <td class=form-widget>
	            [im_category_select_multiple "Intranet Project Status" project_status_ids $project_status_ids 5 multiple]
	          </td>
	        </tr>
	        <tr>
	          <td class=form-label>Company Type</td>
	          <td class=form-widget>
	            [im_category_select -include_empty_p 1 "Intranet Company Type" customer_type_id $customer_type_id]
	          </td>
	        </tr>
	        <tr>
	          <td class=form-label>Company</td>
	          <td class=form-widget>
	            [im_company_select customer_id $customer_id]
	          </td>
	        </tr>
	        <tr>
	          <td class=form-label>Sales Rep</td>
	          <td class=form-widget>
		    [im_options_to_select_box sales_rep_id $sales_rep_options $sales_rep_id]
	          </td>
	        </tr>
	        <tr>
	          <td class=form-label>Format</td>
	          <td class=form-widget>
	            [im_report_output_format_select output_format "" $output_format]
	          </td>
	        </tr>

		<tr>
		  <td class=form-label><nobr>Custom Fields?</nobr></td>
		  <td class=form-widget>
			<input type=checkbox name=custom_fields_p value=1 $custom_fields_checked>
		  </td>
		</tr>


		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>
	</td>
	<td align=center>
		$field_table
	</td>
	<td align=center>
		<table cellspacing=2 width=90%>
		<tr><td>$help_text</td></tr>
		</table>
	</td>
	</tr>
	</table>

	</form>

	<table border=0 cellspacing=1 cellpadding=1>\n"
    }
}

set invoice_total 0
set delnote_total 0
set quote_total 0
set bill_total 0
set po_total 0
set timesheet_total 0
set expense_total 0

set invoice_subtotal 0
set delnote_subtotal 0
set quote_subtotal 0
set bill_subtotal 0
set po_subtotal 0
set timesheet_subtotal 0

set invoice_subsubtotal 0
set delnote_subsubtotal 0
set quote_subsubtotal 0
set bill_subsubtotal 0
set po_subsubtotal 0
set timesheet_subsubtotal 0

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

ns_log Notice "intranet-reporting/finance-projects-documents: sql=\n$sql"

db_foreach sql $sql {

	if {"" == $project_id} {
	    set project_id 0
	    set project_name "No Project"
	}

	im_report_display_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	
	im_report_update_counters -counters $counters
	
	# Calculated Variables 
	set po_per_quote_perc_subsubtotal "undef"
	if {[expr $quote_subsubtotal+0] != 0} {
	  set po_per_quote_perc_subsubtotal [expr int(10000.0 * $po_subsubtotal / $quote_subsubtotal) / 100.0]
	  set po_per_quote_perc_subsubtotal "$po_per_quote_perc_subsubtotal %"
	}
	set gross_profit_subsubtotal [expr $invoice_subsubtotal - $bill_subsubtotal - $expense_subsubtotal]
	set wip_subsubtotal [expr $timesheet_subsubtotal + $bill_subsubtotal + $expense_subsubtotal - $invoice_subsubtotal]


	# Calculated Variables for footer0
	set po_per_quote_perc_subtotal "undef"
	if {[expr $quote_subtotal+0] != 0} {
	    set po_per_quote_perc_subtotal [expr int(10000.0 * $po_subtotal / $quote_subtotal) / 100.0]
	}
	set gross_profit_subtotal [expr $invoice_subtotal - $bill_subtotal - $expense_subtotal]
	set wip_subtotal [expr $timesheet_subtotal + $bill_subtotal + $expense_subtotal - $invoice_subtotal]


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

# Calculated Variables for footer0
set po_per_quote_perc_total "undef"
if {[expr $quote_total+0] != 0} {
    set po_per_quote_perc_total [expr int(10000.0 * $po_total / $quote_total) / 100.0]
}
set gross_profit_total [expr $invoice_total - $bill_total - $expense_total]
set wip_total [expr $timesheet_total + $bill_total + $expense_total - $invoice_total]



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

