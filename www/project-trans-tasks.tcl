# /packages/intranet-reporting/www/finance-quotes-pos.tcl
#
# Copyright (C) 2003-2006 ]project-open[
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
    { level_of_detail 3 }
    { output_format "html" }
    { project_id:integer 0}
    { customer_id:integer 0}
    { project_manager_id:integer 0}
    { project_member_id:integer 0}
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

# ------------------------------------------------------------
# Page Settings

set page_title "Translation Tasks"
set context_bar [im_context_bar $page_title]
set context ""

set help_text "
<strong>Projects and Translation Tasks:</strong><br>
Shows translation tasks groupd by project and customer.<br>

The report shows projects only if the project's end_date is greater
or equal Start Date and less then End Date. 
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

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
set this_url [export_vars -base "/intranet-reporting/project-trans-tasks" {start_date end_date} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}

# Select project & subprojects
if {"" != $project_id && 0 != $project_id} {
    lappend criteria "p.project_id in (
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
    lappend criteria "p.project_lead_id = :project_manager_id"
}

if {"" != $project_member_id && 0 != $project_member_id} {
    lappend criteria "p.project_id in (
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
set today '2006-07-22'

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
	select
		p.project_id,
		p.project_name,
		p.project_nr,
		p.start_date::date as project_start_date,
		p.end_date::date as project_end_date,
		p.project_lead_id as main_project_manager_id,
		im_name_from_user_id(p.project_lead_id) as main_project_manager_name,
		children.project_lead_id as project_manager_id,
		im_name_from_user_id(children.project_lead_id) as project_manager_name,
		children.project_id as children_id,
		children.project_nr as children_nr,
		cust.company_id as customer_id,
		cust.company_path as customer_nr,
		cust.company_name as customer_name,
		t.task_id,
		t.task_name,
		t.task_units,
		t.billable_units,
		t.end_date,
		t.trans_id as trans_user_id,
		im_name_from_user_id(t.trans_id) as trans_user_name,
		t.edit_id as edit_user_id,
		im_name_from_user_id(t.edit_id) as edit_user_name,
		t.proof_id as proof_user_id,
		im_name_from_user_id(t.proof_id) as proof_user_name,
		t.other_id as other_user_id,
		im_name_from_user_id(t.other_id) as other_user_name,
		to_char(t.end_date, :date_format) as task_end_date_formatted,
		to_char(p.end_date, :date_format) as project_end_date_formatted,
		im_category_from_id(t.task_status_id) as task_status,
		im_category_from_id(t.task_type_id) as task_type,
		im_category_from_id(t.source_language_id) as source_language,
		im_category_from_id(t.target_language_id) as target_language,
		im_category_from_id(t.task_uom_id) as task_uom,
		CASE 
			WHEN t.end_date <= :today::date 
			     AND t.task_status_id not in (358, 360) THEN 'red'
			WHEN t.end_date <= (:today::date + :warn_interval::integer)
			     AND t.end_date > :today::date 
			     AND t.task_status_id not in (358, 360) THEN 'orange'
			ELSE 'black'
		END as warn_color
	from
		im_projects p,
		im_projects children,
		im_companies cust,
		im_trans_tasks t
	where
		p.parent_id is null
		and	children.tree_sortkey between
			p.tree_sortkey and tree_right(p.tree_sortkey)
		and p.end_date >= to_date(:start_date, 'YYYY-MM-DD')
		and p.end_date < to_date(:end_date, 'YYYY-MM-DD')
		and p.end_date::date < to_date(:end_date, 'YYYY-MM-DD')
		and p.project_status_id not in ([im_project_status_deleted])
		and p.company_id = cust.company_id
		and children.project_id = t.project_id
		$where_clause
	order by
		cust.company_name,
		p.project_nr,
		children.tree_sortkey
"

set report_def [list \
    group_by customer_id \
    header {
	"\#colspan=17 <a href=$this_url&customer_id=$customer_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$company_url$customer_id>$customer_name</a></b>"
    } \
        content [list \
            group_by project_id \
            header { 
		""
		"<a href=$project_url$project_id>$project_nr</a>"
		"\#colspan=2 <a href=$this_url&project_id=$project_id&level_of_detail=4 
		target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
		<b><a href=$project_url$project_id>$project_nr $project_name</a></b>"
		"<nobr><a href=$user_url$main_project_manager_id>$main_project_manager_name</a></nobr>"
		""
		""
		"$project_end_date_formatted</a>"
		"\#colspan=7 $project_end_date_formatted</a>"
	    } \
	    content [list \
		    header {
			""
			"<a href=$project_url$children_id>$children_nr</a>"
			""
			"$task_name"
			"<nobr><a href=$user_url$project_manager_id>$project_manager_name</a></nobr>"
			"<font color='$warn_color'>$task_end_date_formatted</font>"
			"$source_language"
			"$target_language"
			"<nobr>$task_type</nobr>"
			"$task_status"
			"$task_units"
			"$billable_units"
			"$task_uom"
			"<nobr><a href=$user_url$trans_user_id>$trans_user_name</a></nobr>"
			"<nobr><a href=$user_url$edit_user_id>$edit_user_name</a></nobr>"
			"<nobr><a href=$user_url$proof_user_id>$proof_user_name</a></nobr>"
			"<nobr><a href=$user_url$other_user_id>$other_user_name</a></nobr>"
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
set header0 {"Cus" "Nr" "Project" "Task Name" "PM" "Deadl." "Sr" "Tg" "Type" "Status" "Units" "Bill" "Unit" Trans Edit Proof Other}
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
set levels {1 "Customer Only" 2 "Customer+Project" 3 "All Details"} 

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
                [export_form_vars customer_id project_id]
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
		  <td class=form-label>Project Manager</td>
		  <td class=form-widget>
		    [im_user_select project_manager_id $project_manager_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Project Member</td>
		  <td class=form-widget>
		    [im_user_select project_member_id $project_member_id]
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

ns_log Notice "intranet-reporting/finance-quotes-pos: sql=\n$sql"

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

