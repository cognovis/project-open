# /packages/intranet-reporting/www/program-eva.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Show programs (groups of projects) and their budget
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    {start_date "" }
    {end_date "" }
    {level_of_detail:integer 2 }
    {output_format "html" }
    {program_id:integer 0 }
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
#set menu_label "program-eva"
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

# ------------------------------------------------------------
# Page Settings

set page_title [lang::message::lookup "" intranet-reporting.Program_EVA "Program Earned Value Analysis"]
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong><nobr>$page_title</nobr></strong>
<br>
This report shows programs and the advance of their 
projects vs. their consumed resources (Earned Value Analysis).
<br>
Programs need to be in status 'open' to appear.
Projects need to start before end-date and end 
after start-date.
<br>
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set days_in_past 30

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
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-finance/finance-projects-documents" {start_date end_date} ]
set current_url [im_url_with_query]

# ------------------------------------------------------------
# Options
#

set levels {1 "Programs Only" 2 "Programs and Projects"} 


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {0 != $program_id && "" != $program_id} {
    lappend criteria "pcust.company_id = :program_id"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
	select
		child.*,
		program.project_nr as program_project_nr,
		program.project_name as program_name,
		program.project_status_id as program_status_id,
		program.project_type_id as program_type_id,
		program.project_id as program_project_id,
		to_char(program.percent_completed, '999990') as program_completed_rounded,
		im_category_from_id(child.project_status_id) as project_status,
		im_category_from_id(child.project_type_id) as project_type,
		to_char(child.percent_completed, '999990') as project_completed_rounded
	from
		im_projects program,
		im_projects child
	where
		program.project_type_id in (
			select	*
			from	im_sub_categories([im_project_type_program])
		) and
		child.program_id = program.project_id
	order by
		child.tree_sortkey
"


set report_def [list \
    group_by program_id \
    header {
	"\#colspan=14 <a href=$this_url&program_id=$program_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$project_url$program_id>$program_name</a></b>"
    } \
    content {
	    header { $project_name }
	    content {}
    } \
    footer {$program_id $program_name} \
]


# Global header/footer
set header0 [list "Program" "Project" "Budget" "Budget Hours"]
set footer0 {"" "" "" ""}

set counters [list]

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
	          <td class=form-label>Format</td>
	          <td class=form-widget>
	            [im_report_output_format_select output_format "" $output_format]
	          </td>
	        </tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>
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

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"

db_foreach sql $sql {

    if {"" == $project_id} {
	set project_id 0
	set project_name [lang::message::lookup "" intranet-reporting.No_project "Undefined Project"]
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
