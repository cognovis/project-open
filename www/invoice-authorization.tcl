# /packages/intranet-trans-invoice-authorization/www/invoice-authorization.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    This report shows all translation tasks in a certain status
    by project, freelancer and currency.
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail 3 }
    { output_format "html" }
    { task_status_id:integer 0 }
    { currency "" }
    { project_id:integer 0}
    { provider_id:integer 0}
    { project_manager_id:integer 0}
    { project_member_id:integer 0}
    { invoicing_currency "" }
    { user_id 0 }
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [ad_maybe_redirect_for_registration]
set menu_label "reporting-project-trans-tasks"
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


# user_id is set by the ProjectTransDetails component to indicate the current user.
# Here we are going to copy user_id to the project_member_id,
# unless this variable or the project_manager_id are already set.
if {0 == $project_manager_id && 0 == $project_member_id} {
    set project_member_id $user_id
}

# ------------------------------------------------------------
# Set Project Manager to current user for performance

# project_manager_id = Current User, to reduce performance overhead
if {"" == $start_date && "" == $end_date && 0 == $project_id && 0 == $provider_id && 0 == $project_member_id} {
    set project_manager_id [ad_get_user_id]
}


# ------------------------------------------------------------
# Page Settings

set page_title [lang::message::lookup "" intranet-trans-invoice-authorization.Invoice_Authorization_Wizard "Invoice Authorization Wizard"]
set context_bar [im_context_bar $page_title]
set context ""
set return_url [im_url_with_query]

set help_text [lang::message::lookup "" intranet-trans-invoice-authorization.Invoice_Authorization_Wizard_help "
<strong>$page_title</strong><br>
Shows all translation tasks in a certain status and allows to
create Provider Bill documents per freelancer.<br>
The report shows tasks only if the task's start_date is greater
or equal Start Date and less then End Date. 
"]


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]

set date_format [parameter::get_from_package_key -package_key intranet-translation -parameter "TaskListEndDateFormat" -default [im_l10n_sql_date_format]]

set days_in_past 30
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


set days_after 31
db_1row end_date "
select
	to_char(sysdate::date + :days_after::integer, 'YYYY') as end_year,
	to_char(sysdate::date + :days_after::integer, 'MM') as end_month,
	to_char(sysdate::date + :days_after::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "$end_year-$end_month-01"
}


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="

set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-trans-invoice-authorization/invoice-authorization" {start_date end_date} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {"" != $provider_id && 0 != $provider_id} {
    lappend criteria "prov.company_id = :provider_id"
}

if {"" != $task_status_id && 0 != $task_status_id} {
    lappend criteria "tt.task_status_id = :task_status_id"
}

# Select project & subprojects
if {"" != $project_id && 0 != $project_id} {
    lappend criteria "parent.project_id in (
	select
		p.project_id
	from
		im_projects p,
		im_projects parent_p
	where
		parent_p.project_id = :project_id
		and p.tree_sortkey between parent_p.tree_sortkey and tree_right(parent_p.tree_sortkey)
		and p.project_status_id not in ([im_project_status_deleted])
    )"
}

if {"" != $project_manager_id && 0 != $project_manager_id} {
    lappend criteria "parent.project_lead_id = :project_manager_id"
}

if {"" != $project_member_id && 0 != $project_member_id} {
    lappend criteria "parent.project_id in (
		select	object_id_one
		from	acs_rels
		where	object_id_two = :project_member_id
 	)"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set warn_interval 3
set today [db_string today "select now()::date"]

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
	select
		prov.company_id as provider_id,
		prov.company_name as provider_name,
		child.project_id as child_project_id,
		child.project_nr as child_project_nr,
		c.cost_id as po_id,
		c.cost_nr as po_nr,
		c.cost_name as po_name,
		c.currency as po_currency,
		tt.task_id,
		tt.task_name,
		tt.task_units,
		ii.item_id,
		ii.item_name,
		im_category_from_id(tt.task_status_id) as task_status,
		im_category_from_id(tt.task_type_id) as task_type,
		im_category_from_id(tt.source_language_id) as source_language,
		im_category_from_id(tt.target_language_id) as target_language,
		im_category_from_id(tt.task_uom_id) as task_uom,
		CASE 
			WHEN tt.end_date <= :today::date 
			     AND tt.task_status_id not in (358, 360) THEN 'red'
			WHEN tt.end_date <= (:today::date + :warn_interval::integer)
			     AND tt.end_date > :today::date 
			     AND tt.task_status_id not in (358, 360) THEN 'orange'
			ELSE 'black'
		END as warn_color,
		(select min(bii.invoice_id) from im_invoice_items bii where bii.created_from_item_id = ii.item_id) as bill_invoice_id,
		(select min(bi.invoice_nr) from im_invoice_items bii, im_invoices bi where bii.invoice_id = bi.invoice_id and bii.created_from_item_id = ii.item_id) as bill_invoice_nr
	from
		-- Parent_project has child_project which contains trans_tasks.
		-- Task_id is referenced by PO invoice_items. Its invoice is linked to provider.
		im_projects parent,
		im_projects child,
		im_trans_tasks tt,
		im_invoice_items ii,
		im_costs c,
		im_invoices i,
		im_companies prov
	where
		parent.parent_id is null
		and child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_status_id not in ([im_project_status_deleted])
		and child.project_status_id not in ([im_project_status_deleted])
		and child.project_id = tt.project_id
		and tt.task_id = ii.task_id
		and ii.invoice_id = i.invoice_id
		and i.invoice_id = c.cost_id
		and c.provider_id = prov.company_id
		and c.cost_type_id = [im_cost_type_po]
		$where_clause
	order by
		po_currency,
		provider_name,
		child.project_nr,
		c.cost_name,
		parent.project_nr,
		child.tree_sortkey
"

# 		and tt.end_date >= to_date(:start_date, 'YYYY-MM-DD')
#		and tt.end_date <= to_date(:end_date, 'YYYY-MM-DD')
#		and tt.end_date::date < :end_date::date




set report_def [list \
    group_by po_currency \
    header {
	"\#colspan=17 <a href=$this_url&currency=$po_currency&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b>Currency: $po_currency</b>"
    } \
        content [list \
            group_by provider_id \
            header { 
		""
		"\#colspan=16 <a href=$this_url&provider_id=$provider_id&level_of_detail=4 
		target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
		<b><a href=$company_url$provider_id>$provider_name</a></b>"
	    } \
	    content [list \
		    header {
			"<input type=checkbox value=$item_id name=invoice_item_id $checkbox_checked>"
			"<a href=$project_url$child_project_id>$child_project_nr</a>"
			"<a href=$invoice_url$po_id>$po_name</a>"
			"$item_name"
			"$source_language"
			"$target_language"
			"$task_status"
			"<nobr>$task_type</nobr>"
			"$task_units"
			"$task_uom"
			"$bill_invoice_html"
		    } \
		    content {} \
	    ] \
	    footer {
		"&nbsp;" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
            } \
    ] \
    footer {  
	"&nbsp;"  ""  ""  ""  ""  ""  ""  ""  ""  ""  "" "" "" "" "" "" ""
    } \
]

# Global header/footer
set header0 {"Cur" "Project" "PO" "Task Name" "Src" "Tgt" "Status" "Type" "Units" "Unit" "Auth"}
set footer0 {
	"&nbsp;"  ""  ""  ""  ""  ""  ""  ""  ""  ""  "" "" "" "" "" "" ""
}

set counters [list ]


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 "Currency Only" 2 "Currency + Provider" 3 "All Details"} 

set task_status_options [db_list_of_lists task_status_options "
	select	category,
		category_id
	from	im_categories
	where	category_type = 'Intranet Translation Task Status'
	order by sort_order
"]
set task_status_options [linsert $task_status_options 0 [list "All" ""]]


set provider_options [db_list_of_lists task_status_options "
	select	company_name,
		company_id
	from	im_companies
	where	company_id in (
			select	c.provider_id
			from	im_costs c
			where	c.cost_type_id = [im_cost_type_po]
		)
	order by lower(company_name)
"]
set provider_options [linsert $provider_options 0 [list "All" ""]]

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
	<form method=GET>
                [export_form_vars]
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
		  <td class=form-label>Provider</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 -ad_form_option_list_style_p 1 provider_id $provider_options $provider_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Currency</td>
		  <td class=form-widget>
		    [im_currency_select -translate_p 0 -include_empty_name "All" currency $currency]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Task Status</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 -ad_form_option_list_style_p 1 task_status_id $task_status_options $task_status_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Project Manager</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -group_id [im_profile_employees] project_manager_id $project_manager_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Project Member</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -group_id [im_profile_employees] project_member_id $project_member_id]
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
	</form>
	</td>
	<td align=center>
		<table cellspacing=2>
		<tr><td>$help_text</td></tr>
		</table>
	</td>
	</tr>
	</table>

	<form action=generate-provider-bills method=GET>
	[export_form_vars return_url]
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

ns_log Notice "intranet-reporting-translation/finance-quotes-pos: sql=\n$sql"

db_foreach sql $sql {

	if {"" == $project_id} {
	    set project_id 0
	    set project_name [lang::message::lookup "" intranet-reporting.No_project "Undefined Project"]
	}

	# Check if there is already a payment authorization for this PO line
	# and uncheck the box by default.
	set checkbox_checked "checked"
	set bill_invoice_html ""
	if {"" != $bill_invoice_id} { 
	    set checkbox_checked "" 
	    set bill_invoice_html "<a href=$invoice_url$bill_invoice_id>$bill_invoice_nr</a>"
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
    html { 
	ns_write "<tr><td colspan=99>
		<input type=submit value='[lang::message::lookup "" intranet-trans-invoice-authorization.Authorize_Payment_for_Selected_Tasks "Authorize Payment for Selected Tasks"]'>
		</td></tr>
	"
	ns_write "</table>\n"
	ns_write "</form>\n"
	ns_write [im_footer]
    }
}

