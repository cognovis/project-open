# /packages/intranet-reporting/www/budget-main-projects.tcl
#
# Copyright (c) 2003-2013 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Budget Check for Main Projects Report

    This reports lists all main projects with a budget overrun.
    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
    @level_of_detail Integer representing the level to which report 
		     groupings are opened
} {
    { start_date "2011-01-01" }
    { end_date "2099-12-31" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
    { output_format "html" }
    { number_locale "" }

}


# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

# What is the "label" of the Menu Item linking to this report?
set menu_label "reporting-budget-main-projects"

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


set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }


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

set page_title "Budget Check for Main Projects"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Check the main project's budget:</strong><br>
	The report lists all main projects with a set 'Budget' or 'Budget Hours' field
	in the given interval.<br>
	<ul>
	<li><b>%Compl</b>: Completion degree of the project. Calculated automatically from the
	    completion of sub-projects and tasks.

	<li><b>Budget Hours</b>: The manually specified budget hours for the project.
	<li><b>Logged Hours</b>: All hours logged on the project and its sub-projects and tasks.
	    Red color indicates that the hourly budget has been exceeded.
	<li><b>EoP Hours</b> (End of Project Hours): = Logged Hours / %Comp. Represents the hours necessary
	    to finish the project at the current pace.
	    Brown color indicates that the project will exceed the hourly budget.

	<li><b>Budget Costs</b>: The manually specified budget for the project.
	<li><b>Logged Costs</b>: All costs logged on the project and its sub-projects and tasks.
	    Red color indicates that the budget has been exceeded.
	<li><b>EoP Costs</b> (End of Project Costs): = Logged Costs / %Comp. Represents the costs necessary
	    to finish the project at the current pace. Brown color indicates that the project 
	    will exceed the budget.

	</ul>
	The interval defaults to 2000-01-01 - 2100-01-01.<br>
	<strong>Please Note:</strong><br>
	<ul>
	<li>	This report is not designed to show budgets on sub-projects and below.
		Instead, the report assumes that budgets are assigned only to main projects and that
		the progress of sub-projects and tasks is tracked based on the 'estimated hours' vs. 
		'logged hours' in each project.</li>
	</ul>
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
set currency_format "999,999,999"
set percent_format "999.9"
set date_format "YYYY-MM-DD"
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]


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
	select	p.*,
		eop_hours,
		eop_costs,
		real_total,

		CASE WHEN project_budget < 0.1 THEN null
		     ELSE round(1000 * (eop_costs - project_budget) / project_budget) / 10.0
		END as percent_overrun

	from	(select
			p.*,
			im_name_from_user_id(p.project_lead_id) as project_lead_name,

			-- Hours
			round(p.project_budget_hours) as budget_hours,
			round(p.reported_hours_cache) as logged_hours,
			CASE WHEN percent_completed < 0.1 THEN null
			     ELSE p.reported_hours_cache * 100 / percent_completed
			END as eop_hours,

			-- Planned Costs
			p.cost_purchase_orders_cache as budget_providers,
			p.cost_timesheet_planned_cache as budget_timesheet,
			p.cost_expense_planned_cache as budget_expenses,
			p.cost_purchase_orders_cache + p.cost_timesheet_planned_cache + p.cost_expense_planned_cache as budget_total,
			p.project_budget as budget_manual,

			CASE WHEN percent_completed < 0.1 THEN null
			     ELSE (coalesce(p.cost_bills_cache, 0) + 
			     	   coalesce(p.cost_timesheet_logged_cache, 0) + 
				   coalesce(p.cost_expense_logged_cache, 0)) * 100 / percent_completed
			END as eop_costs,

			p.cost_bills_cache as real_providers,
			p.cost_timesheet_logged_cache as real_timesheet,
			p.cost_expense_logged_cache as real_expenses,
			p.cost_bills_cache + p.cost_timesheet_logged_cache + p.cost_expense_logged_cache as real_total,

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
		lower(customer_name),
		lower(project_name)
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

        "|<br>|"

	"Budget<br>Hours"
	"Logged<br>Hours"
	"EoP<br>Hours"

        "|<br>|"

	"Planned<br>Providers"
	"Planned<br>Timesheet"
	"Planned<br>Expenses"
	"Planned<br>Total"
	"Budget"

        "|<br>|"

	"Real<br>Providers"
	"Real<br>Timesheet"
	"Real<br>Expenses"
	"Real<br>Total"
	"EoP<br>Total"

        "|<br>|"

	"Overrun"
}


# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by customer_id \
    header {
	"\#colspan=23 <a href=$this_url&customer_id=$customer_id&level_of_detail=4 
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

			"\#align=center |"

			"\#align=right $budget_hours_pretty"
			"\#align=right <font color=$logged_hours_color>$logged_hours_pretty</font>"
			"\#align=right <font color=$eop_hours_color>$eop_hours_pretty</font>"

			"\#align=center |"

			"\#align=right $budget_providers_pretty"
			"\#align=right $budget_timesheet_pretty"
			"\#align=right $budget_expenses_pretty"
			"\#align=right $budget_total_pretty"
			"\#align=right $budget_manual_pretty"

			"\#align=center |"

			"\#align=right $real_providers_pretty"
			"\#align=right $real_timesheet_pretty"
			"\#align=right $real_expenses_pretty"
			"\#align=right <font color=$real_total_color>$real_total_pretty</font>"
			"\#align=right <font color=$eop_costs_color>$eop_costs_pretty</font>"

			"\#align=center |"

			"\#align=right <font color=$overrun_color>$percent_overrun_pretty</font>"
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

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -report_name $page_title -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header $page_title]
	[im_navbar reporting]
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
    }
    printer {
        ns_write "
        <link rel=StyleSheet type='text/css' href='/intranet-reporting/printer-friendly.css' media=all>
        <div class=\"fullwidth-list\">
        <table border=0 cellspacing=1 cellpadding=1 rules=all>
        <colgroup>
                <col id=datecol>
                <col id=hourcol>
                <col id=datecol>
                <col id=datecol>
                <col id=hourcol>
                <col id=hourcol>
                <col id=hourcol>
        </colgroup>
        "
    }
}



# The following report loop is "magic", that means that 
# you don't have to fully understand what it does.

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -output_format $output_format \
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
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

	# Color=red if logged hours > budget hours
	set logged_hours_color "black"
	if {"" != $budget_hours && "" != $logged_hours} {
	    if {$logged_hours > $budget_hours} {
		set logged_hours_color "red"
	    }
	}

	# Color=red if logged estimated_hours > budget_hours
	set eop_hours_color "black"
	if {"" != $eop_hours && "" != $budget_hours} {
	    ns_log Notice "EoP: eop_hours=$eop_hours, budget_hours=$budget_hours"
	    if {$eop_hours > $budget_hours} {
		set eop_hours_color "red"
	    }
	}

	# Color=orange if logged estimated_costs > budget
	set eop_costs_color "black"
	if {"" != $project_budget && "" != $eop_costs} {
	    if {$eop_costs > $project_budget} {
		set eop_costs_color "red"
	    }
	}

	# Color=red if logged real_total > budget
	set real_total_color "black"
	if {"" != $project_budget && "" != $real_total} {
	    if {$real_total > $project_budget} {
		set real_total_color "red"
	    }
	}

	set percent_overrun_pretty ""
	if {"" != $percent_overrun} {
	    set percent_overrun_pretty [im_report_format_number $percent_overrun $output_format $number_locale]
	}

	set eop_hours_pretty ""
	if {"" != $eop_hours} {
	    set eop_hours_pretty [im_report_format_number [expr round(10.0 * $eop_hours) / 10.0] $output_format $number_locale]
	}

	set eop_costs_pretty ""
	if {"" != $eop_costs} {
	    set eop_costs_pretty [im_report_format_number [expr round(10.0 * $eop_costs) / 10.0] $output_format $number_locale]
	}

	set percent_completed_pretty ""
	if {"" != $percent_completed} {
	    set percent_completed_pretty [im_report_format_number [expr round(10.0 * $percent_completed) / 10.0] $output_format $number_locale]
	}

	set budget_hours_pretty [im_report_format_number $budget_hours $output_format $number_locale]
	set logged_hours_pretty [im_report_format_number $logged_hours $output_format $number_locale]
	set budget_providers_pretty [im_report_format_number $budget_providers $output_format $number_locale]
	set budget_timesheet_pretty [im_report_format_number $budget_timesheet $output_format $number_locale]
	set budget_expenses_pretty [im_report_format_number $budget_expenses $output_format $number_locale]
	set budget_total_pretty [im_report_format_number $budget_total $output_format $number_locale]
	set budget_manual_pretty [im_report_format_number $budget_manual $output_format $number_locale]
	set real_providers_pretty [im_report_format_number $real_providers $output_format $number_locale]
	set real_timesheet_pretty [im_report_format_number $real_timesheet $output_format $number_locale]
	set real_expenses_pretty [im_report_format_number $real_expenses $output_format $number_locale]
	set real_total_pretty [im_report_format_number $real_total $output_format $number_locale]
	set percent_overrun_pretty [im_report_format_number $percent_overrun $output_format $number_locale]

	# Color=red if overrun > 0
	set overrun_color "black"
	if {"" != $percent_overrun && $percent_overrun > 0} {
	    set overrun_color "red"
	}

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

	incr counter
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


# Write out the HTMl to close the main report table
# and write out the page footer.
#

# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>[im_footer]\n" }
    printer { ns_write "</table>\n</div>\n" }
    cvs { }
}

