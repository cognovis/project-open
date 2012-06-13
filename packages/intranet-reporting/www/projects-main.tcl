# /packages/intranet-reporting/www/projects-main.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Report listing all main projects in the system with all available
    fields + DynFields from projects and customers
} {
    { level_of_detail 2 }
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { number_locale "" }
    { project_id:integer 0}
    { project_status_id:integer 0}
    { project_type_id:integer 0}
    { company_id:integer 0}
    { company_status_id:integer 0}
    { company_type_id:integer 0}
    { member_id:integer 0}
    { project_lead_id:integer 0}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-projects-main"
set current_user_id [ad_maybe_redirect_for_registration]
# Default User = Current User, to reduce performance overhead
if {"" == $start_date && "" == $end_date && 0 == $project_id && 0 == $company_id && 0 == $member_id && 0 == $project_lead_id} { 
    set user_id $current_user_id 
}
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default "f"]


# ------------------------------------------------------------
# Constants

set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }

set date_format "YYYY-MM-DD"
set number_format "999,999.99"


# ------------------------------------------------------------

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set page_title "Project Report \[Beta\]"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

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
    set end_date "2099-12-31"
}


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/projects-main" {start_date end_date level_of_detail project_id task_id company_id user_id} ]

# BaseURL for drill-down. Needs company_id, project_id, user_id, level_of_detail
set base_url [export_vars -base "/intranet-reporting/projects-main" {start_date end_date task_id} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {0 != $project_status_id && "" != $project_status_id} { lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])" }
if {0 != $project_type_id && "" != $project_type_id} { lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])" }
if {0 != $company_status_id && "" != $company_status_id} { lappend criteria "c.company_status_id in ([join [im_sub_categories $company_status_id] ","])" }
if {0 != $company_type_id && "" != $company_type_id} { lappend criteria "p.company_type_id in ([join [im_sub_categories $company_type_id] ","])" }

if {0 != $company_id && "" != $company_id} { lappend criteria "p.company_id = :company_id" }
if {0 != $member_id && "" != $member_id} {
    lappend criteria "p.project_id in (
	select	r.object_id_one
	from	acs_rels r, im_projects p
	where	r.object_id_one = p.project_id and r.object_id_two = 624
    )"
}
if {0 != $project_lead_id && "" != $project_lead_id} { lappend criteria "p.project_lead_id = :project_lead_id" }
if {0 != $project_id && "" != $project_id} { lappend criteria "p.project_id = :project_id" }

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# List of project variables to show

# Global header/footer
set header0 {"Customer" "ProjectNr" "ProjectName" Start End Type Status PM FinalCust FinalCustProjectNr FinalCustContact Budget Cur BudgetHours PercCompl LoggedHours Invoices DelNotes Quotes Bills POs Expenses Timesheet}
set footer0 {}
set counters [list]

# Variables per project
set project_vars {
    $company_name 
    "<!--<a href=$base_url&project_id=$project_id&level_of_detail=4 target=_blank><img src=/intranet/images/plus_9.gif border=0></a>-->
    <b><a href=$project_url$project_id>$project_nr<!--</a>--></b>"
    $project_name
    $project_start_date
    $project_end_date
    $project_type
    $project_status
    "<a href=$user_url$project_lead_id>$project_lead_name</a>"
    $final_company
    $company_project_nr
    "<a href=$user_url$company_contact_id>$company_contact_name</a>"
    $project_budget_pretty
    $project_budget_currency
    $project_budget_hours_pretty
    $percent_completed_pretty
    $reported_hours_cache_pretty
    $cost_invoices_cache_pretty
    $cost_delivery_notes_cache_pretty
    $cost_quotes_cache_pretty
    $cost_bills_cache_pretty
    $cost_purchase_orders_cache_pretty
    $cost_expense_logged_cache_pretty
    $cost_timesheet_logged_cache_pretty
}



# ------------------------------------------------------------
# Add all Project and Company DynFields to list

set dynfield_sql "
	select	aa.attribute_name,
		aa.pretty_name,
		w.widget as tcl_widget,
		w.widget_name as dynfield_widget
	from
		im_dynfield_attributes a,
		im_dynfield_widgets w,
		acs_attributes aa
	where
		a.widget_name = w.widget_name
		and a.acs_attribute_id = aa.attribute_id
		and aa.object_type in ('im_project','im_company')
		and aa.attribute_name not like 'default%'
		and aa.attribute_name != 'note'
	order by
		aa.object_type,
		aa.sort_order
"

set derefs [list]
db_foreach dynfield_attributes $dynfield_sql {

    if { "company_id" == $attribute_name } {
        break
    }

    # Catch the generic ones - We know how to dereferentiate integer references of these fields.
    set deref ""
    switch $tcl_widget {
	im_category_tree {
	    set deref "im_category_from_id($attribute_name) as ${attribute_name}_deref"
	}
	im_cost_center_tree {
	    set deref "im_cost_center_name_from_id($attribute_name) as ${attribute_name}_deref"
	}
    }

    switch $dynfield_widget {
	gender_select { set deref "im_category_from_id($attribute_name) as ${attribute_name}_deref" }
	employees { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	employees_and_customers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	customers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	bit_member { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	active_projects { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	cost_centers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	project_account_manager { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	pl_fachbereich { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
    }
	
    if {"" == $deref} { set deref "$attribute_name as ${attribute_name}_deref" }
    lappend header0 $pretty_name
    lappend derefs $deref
    set var_name "\$${attribute_name}_deref"
    lappend project_vars $var_name
}



# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
select
	p.*,
	im_category_from_id(p.project_status_id) as project_status,
	im_category_from_id(p.project_type_id) as project_type,
	to_char(p.start_date, :date_format) as project_start_date,
	to_char(p.end_date, :date_format) as project_end_date,
	im_name_from_user_id(p.project_lead_id) as project_lead_name,
	im_name_from_user_id(p.company_contact_id) as company_contact_name,
	round(p.percent_completed::numeric, 2) as percent_completed_rounded,
	c.*,
	im_category_from_id(c.company_status_id) as company_status,
	im_category_from_id(c.company_type_id) as company_type,
	c.company_path as company_nr,
	[join $derefs "\t,\n"]
from
	im_projects p,
	im_companies c
where
	p.parent_id is null and
	p.company_id = c.company_id
	and p.project_status_id not in ([im_project_status_deleted])
	and p.end_date >= to_timestamp(:start_date, 'YYYY-MM-DD')
	and p.end_date < to_timestamp(:end_date, 'YYYY-MM-DD')
	$where_clause
order by
	c.company_name,
	p.project_name
"



switch $output_format {
    html {
	set report_def [list \
	    group_by company_nr \
	    header {
		"\#colspan=99 <!--<a href=$base_url&company_id=$company_id&level_of_detail=4 target=_blank><img src=/intranet/images/plus_9.gif border=0></a>--> <b><a href=$company_url$company_id>$company_name</a></b>"
	    } \
	    content [list \
		 header $project_vars \
		 content [list]
	    ] \
	    footer {"" "" "" "" "" "" ""} \
	]
    }
    default {
	set report_def [list \
		group_by project_nr \
		header $project_vars \
		content [list] \
		footer [list] \
	]
    }
}


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 "Customer Only" 2 "Customer+Project"} 

# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header $page_title]
	[im_navbar]
	<form>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr valign=top><td>
		<table border=0 cellspacing=1 cellpadding=1>
		<!-- 
		<tr>
	          <td class=form-label>Level of Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		--> 
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
		  <td class=form-label>Customer</td>
		  <td class=form-widget>
		    [im_company_select company_id $company_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Project Manager</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" project_lead_id $project_lead_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Project Member</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" user_id $member_id]
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
	</td><td>
		<table border=0 cellspacing=1 cellpadding=1>
		</table>
	</td></tr>
	</table>
	</form>
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
db_foreach sql $sql {

    set percent_completed_pretty		[im_report_format_number $percent_completed_rounded $output_format $number_locale]

    set project_budget_pretty			[im_report_format_number $project_budget $output_format $number_locale]
    set project_budget_hours_pretty		[im_report_format_number $project_budget_hours $output_format $number_locale]
    set reported_hours_cache_pretty		[im_report_format_number $reported_hours_cache $output_format $number_locale]

    set cost_invoices_cache_pretty		[im_report_format_number $cost_invoices_cache $output_format $number_locale]
    set cost_delivery_notes_cache_pretty	[im_report_format_number $cost_delivery_notes_cache $output_format $number_locale]
    set cost_quotes_cache_pretty		[im_report_format_number $cost_quotes_cache $output_format $number_locale]
    set cost_bills_cache_pretty			[im_report_format_number $cost_bills_cache $output_format $number_locale]
    set cost_purchase_orders_cache_pretty	[im_report_format_number $cost_purchase_orders_cache $output_format $number_locale]
    set cost_expense_logged_cache_pretty	[im_report_format_number $cost_expense_logged_cache $output_format $number_locale]
    set cost_timesheet_logged_cache_pretty	[im_report_format_number $cost_timesheet_logged_cache $output_format $number_locale]

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
    -cell_class $class


# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>\n[im_footer]\n"}
}
