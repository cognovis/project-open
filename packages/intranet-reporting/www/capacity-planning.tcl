# /packages/intranet-reporting/www/budget-main-projects.tcl
#
# Copyright (c) 2003-2009 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Budget for Main Projects Report

    This reports lists all main projects with a budget overrun.
    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
    @level_of_detail Integer representing the level to which report 
		     groupings are opened
} {
    { start_date "2009-01-01" }
    { end_date "2099-12-31" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
}


# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

# What is the "label" of the Menu Item linking to this report?
set menu_label "reporting-capacity-planning"

# Get the current user
set current_user_id [ad_maybe_redirect_for_registration]

# Determine whether the current_user has read permissions. 
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# Write out an error message if the current user doesn't have read permissions
if {![string equal "t" $read_p]} {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}



# ------------------------------------------------------------
# Check Parameters
# ------------------------------------------------------------

# Check that start_date and end_date have correct format.
# We are using a regular expression check here for convenience.

if {![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
    ad_script_abort
}

if {![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
    ad_script_abort
}

# Maxlevel is 3. 
if {$level_of_detail > 3} { set level_of_detail 3 }



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
# ------------------------------------------------------------

set page_title "Capacity Planning"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Capacity Planing:</strong><br>
	The report lists all main projects with a set 'Budget' or 'Budget Hours' field
	in the given interval.<br>
	<ul>
	<li><b>%Compl</b>
	</ul>
	The interval defaults to 2000-01-01 - 2100-01-01.
"


# ------------------------------------------------------------
# Default Values and Constants
# ------------------------------------------------------------

# Default report line formatting - alternating between the
# CSS styles "roweven" (grey) and "rowodd" (lighter grey).
#
set rowclass(0) "roweven"
set rowclass(1) "rowodd"

# Variable formatting - Default formatting is quite ugly
# normally. In the future we will include locale specific
# formatting. 
#
set currency_format "999,999,999.09"
set percent_format "999.9"
set date_format "YYYY-MM-DD"


# Set URLs on how to get to other parts of the system
# for convenience. (New!)
# This_url includes the parameters passed on to this report.
#
set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="

set this_url [export_vars -base "/intranet-reporting/budget-main-projects" {start_date end_date} ]

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels {3 "Customers + Projects"} 



# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.

set customer_sql ""
if {0 != $customer_id} {
    set customer_sql "and p.company_id = :customer_id\n"
}

set report_sql "
	select
		p.*,
		to_char(p.project_budget, :currency_format) as budget_pretty,
		to_char(p.percent_completed, :percent_format) as percent_completed_pretty,
		to_char(p.logged_costs, :currency_format) as logged_costs_pretty
	from
		(select
			p.*,
			im_name_from_user_id(p.project_lead_id) as project_lead_name,
			p.project_budget_hours as budget_hours,
			p.cost_timesheet_logged_cache as logged_hours,
			coalesce(p.cost_invoices_cache, 0) + coalesce(p.cost_timesheet_logged_cache, 0) + coalesce(p.cost_bills_cache, 0) + coalesce(p.cost_expense_logged_cache, 0) as logged_costs,
			cust.company_id as customer_id,
			cust.company_path as customer_nr,
			cust.company_name as customer_name
		from
			im_projects p,
			im_companies cust
		where
			p.company_id = cust.company_id and
			p.parent_id is NULL and
			(p.project_budget is not NULL OR p.project_budget_hours is not NULL)
		) p
	order by
		lower(p.customer_name),
		lower(p.project_name)
"

# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 {
	"Cust"
	"Project<br>Nr" 
	"Project<br>Name" 
	"Project<br>Manager" 
	"%<br>Compl"
	"Budget<br>Hours"
	"Logged<br>Hours"
	"Estim<br>Hours"
	"Budget<br>Costs"
	"Logged<br>Costs"
	"Estim<br>Costs"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by customer_id \
    header {
	"\#colspan=11 <a href=$this_url&customer_id=$customer_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$company_url$customer_id>$customer_name</a></b>"
    } \
	content [list \
	    group_by project_id \
	    header { } \
	    content [list \
		    header {
			""
			"<a href='$project_url$project_id'>$project_nr</a>"
			$project_name
			"<a href='$user_url$project_lead_id'>$project_lead_name</a>"
			"\#align=right $percent_completed_pretty%"
			"\#align=right $budget_hours"
			"\#align=right <font color=$logged_hours_color>$logged_hours</font>"
			"\#align=right <font color=$estim_hours_color>$estim_hours</font>"
			"\#align=right $budget_pretty"
			"\#align=right <font color=$logged_costs_color>$logged_costs_pretty</font>"
			"\#align=right <font color=$estim_costs_color>$estim_costs</font>"
		    } \
		    content {} \
	    ] \
	    footer {
	    } \
    ] \
    footer { 
    } \
]


# Global Footer Line
set footer0 { }


# ------------------------------------------------------------
# Counters

set counters [list ]


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

ad_return_top_of_page "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0 width='100%'>
	<tr valign=top>
	  <td>
		<!-- 'Filters' - Show the Report parameters -->
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td>Level of<br>Details</td>
		  <td>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td><nobr>Start Date:</nobr></td>
		  <td><input type=text name=start_date value='$start_date'></td>
		</tr>
		<tr>
		  <td>End Date:</td>
		  <td><input type=text name=end_date value='$end_date'></td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='Submit'></td>
		</tr>
		</table>
		</form>
	  </td>
	  <td align=center>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	<tr><td colspan=2>&nbsp;</td></tr>
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
"

# The following report loop is "magic", that means that 
# you don't have to fully understand what it does.

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
set class ""
db_foreach sql $report_sql {

	# Select either "roweven" or "rowodd"
	set class $rowclass([expr $counter % 2])

	# Restrict the length of the project_name to max. 40 characters.
	set project_name [string_truncate -len 40 $project_name]

	im_report_display_footer \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

	# Calculated Variables
	set estim_hours ""
	catch { set estim_hours [expr round(10 * $logged_hours * 100 / $percent_completed) / 10] }
	set estim_costs ""
	catch { set estim_costs [expr round(10 * $logged_costs * 100 / $percent_completed) / 10] }

	# Color=red if logged hours > budget hours
	set logged_hours_color "black"
	if {"" != $budget_hours && "" != $logged_hours} {
	    if {$logged_hours > $budget_hours} {
		set logged_hours_color "red"
	    }
	}

	# Color=orange if logged estimated_hours > budget hours
	set estim_hours_color "black"
	if {"" != $estim_hours && "" != $budget_hours} {
	    if {$estim_hours > $budget_hours} {
		set estim_hours_color "brown"
	    }
	}

	# Color=red if logged costs > budget
	set logged_costs_color "black"
	if {"" != $project_budget && "" != $logged_costs} {
	    if {$logged_costs > $project_budget} {
		set logged_costs_color "red"
	    }
	}

	# Color=orange if logged estimated_costs > budget
	set estim_costs_color "black"
	if {"" != $project_budget && "" != $estim_costs} {
	    if {$estim_costs > $project_budget} {
		set estim_costs_color "brown"
	    }
	}

	set last_value_list [im_report_render_header \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	set footer_array_list [im_report_render_footer \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	incr counter
}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1


# Write out the HTMl to close the main report table
# and write out the page footer.
#
ns_write "
	</table>
	[im_footer]
"

