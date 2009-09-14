# /packages/intranet-reporting-tutorial/www/projects-03.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Projects-03 Tutorial Contents
#
# This report contains everything from projects-01 plus
# some new features. Search for "New!" for the new stuff:
#
# - Security
# - Parameter value checks using Regular Expressions
# - HREF links to users and projects
# - Field Length Restriction
# - Simple Joins


# ------------------------------------------------------------
# Page Contract 
#
# This section give some comments about the page for the 
# automatic documentation function and defines parameters 
# with their default values.
# You can overwrite the default values by specifying the
# parameters in the URL, for example:
# http://your_server/intranet-reporting-tutorial/ ...
# ... /projects-03?start_date=2006-01-01&end_date=2006-12-31
#

ad_page_contract {
    Reporting Tutorial "projects-03" Report
    This reports lists all projects in a time interval
    It is one of the easiest reports imaginable...

    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
} {
    { start_date "2005-01-01" }
    { end_date "2099-12-31" }
}


# ------------------------------------------------------------
# Security (New!)
#
# The access permissions for the report are taken from the
# "im_menu" Menu Items in the "Reports" section that link 
# to this report. It's just a convenient way to handle 
# security, that avoids errors (different rights for the 
# Menu Item then for the report) and redundancy.

# What is the "label" of the Menu Item linking to this report?
set menu_label "reporting-tutorial-projects-03"

# Get the current user and make sure that he or she is
# logged in. Registration is handeled transparently - 
# the user is redirected to this URL after registration 
# if he wasn't logged in.
set current_user_id [ad_maybe_redirect_for_registration]

# Determine whether the current_user has read permissions. 
# "db_string" takes a name as the first argument 
# ("report_perms") and then executes the SQL statement in 
# the second argument. 
# It returns an error if there is more then one result row.
# im_object_permission_p is a PlPg/SQL procedure that is 
# defined as part of ]project-open[.
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# For testing - set manually
set read_p "t"

# Write out an error message if the current user doesn't
# have read permissions and abort the execution of the
# current screen.
if {![string equal "t" $read_p]} {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}



# ------------------------------------------------------------
# Check Parameters (New!)
#
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



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#
# We always need a "page_title".
# The "context_bar" defines the "bread crums" at the top of the
# page that allow a user to return to the home page and to
# navigate the site.
# Every reports should contain a "help_text" that explains in
# detail what exactly is shown. Reports can get very messy and
# it can become very difficult to interpret the data shown.
#

set page_title "Projects-03 Tutorial Report"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Projects-03 Tutorial Report:</strong><br>
	This is the third reports of the Reporting Tutorial.
	The report shows all projects if their end_date is inside
	the interval between start_date and end_date, including
	the start_date, but excluding the end_date.
	The interval defaults to 2000-01-01 - 2100-01-01.
	Please see the <a href=\"source?source=projects-03\">source code</a> for details.
"


# ------------------------------------------------------------
# Default Values and Constants
#
# In this section we define constants and default variables
# that are used in the sections further below.
#

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
set date_format "YYYY-MM-DD"

# Set URLs on how to get to other parts of the system
# for convenience. (New!)
# This_url includes the parameters passed on to this report.
#
set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-tutorial/projects-03" {start_date end_date} ]

# Level of Details
# Will be used more extensively with groupings
#
set level_of_detail 1


# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.
#
# This section is usually the starting point when starting 
# any new report.
# Once your SQL is fine you you start adding formatting, 
# grouping and filters to create a "real-world" report.
#

# This version of the select query uses a join with 
# im_companies on (p.company_id = company.company_id).
# This join is possible, because the p.company_id field
# is a non-null field constraint via referential integrity
# to the im_companies table.
# In the absence of such strong integrity contraints you
# will have to use "LEFT OUTER JOIN"s instead. (New!)
#
set report_sql "
	select
		p.*,
		cust.company_path as customer_nr,
		cust.company_name as customer_name,

		to_char(p.start_date, :date_format) as start_date_formatted,
		to_char(p.end_date, :date_format) as end_date_formatted,
		im_name_from_user_id(p.project_lead_id) as project_lead_name,

		to_char(p.cost_invoices_cache, :currency_format) as invoices,
		to_char(p.cost_quotes_cache, :currency_format) as quotes,
		to_char(p.cost_delivery_notes_cache, :currency_format) as delnotes,
		to_char(p.cost_purchase_orders_cache, :currency_format) as pos,
		to_char(p.cost_bills_cache, :currency_format) as bills,
		to_char(p.cost_expense_logged_cache, :currency_format) as expenses
	from
		im_projects p,
		im_companies cust
	where
		p.company_id = cust.company_id
		and parent_id is null
		and p.end_date >= :start_date
		and p.end_date <= :end_date
	
	order by
		p.end_date DESC
"


# Report SQL Explanation:
#
# The Report SQL returns all details that you might ever
# want to show to a user. You will later be able to "fold in"
# some details and hide them from the users, but here you
# start with everything you've got. Don't be afraid that your
# report may return millions of lines, ]project-open[ will be
# able to deal with it, even if it takes a minute or two to
# format the report.
#
#	select
#		p.*,
#
# Selecting "p.*" selects ALL fields from the "im_projects"
# table. This usually is just convenient. The SQL columns 
# of the "im_projects" table just become local variables. 
# The SQL variables in ]project-open[ / OpenACS are (almost 
# always) named in a suitable way to avoid duplicates etc.
#
#		p.start_date::date as start_date_formatted,
#		p.end_date::date as end_date_formatted,
#		im_name_from_user_id(p.project_lead_id) as project_lead_name
#
# These lines demonstrate some basic formatting applied to
# table fields: 
#
#	- "to_char(var, format) is a PostgreSQL way to format the
#	  value.
#
#	- "as start_date_formatted" is used to return the formatted
#	  value as a different variable then the original value.
#	  This "start_date_formatted" then appears as a local variable,
#	  just like all the other table columns.
#
#	- "im_name_from_user_id(user_id)" is a shortcut
#	  procedure that does that - it returns the name of
#	  a user given it's user_id.
#
# Where Clause:
#
#	where
#		parent_id is null
#
# "parent_id" indicates the project's parent project.
# So this clause eliminates any subprojects from the list.
#
#		and p.end_date >= :start_date
#		and p.end_date <= :end_date
#
# Please note the SQL "colon variables". Colon variables
# are different from normal variables ("string variables",
# "$start_date") by the moment of dereferentiation.
# Colon variables are dereferenced _inside_ the PostgreSQL
# SQL driver, so that the usual "SQL injection" security
# attacks don't work. Try yourself setting setting "start_date"
# to "2000-01-01; delete * from projects; select " or similar.
#
#	order by
#		p.end_date DESC
#
# The "order by" clause is obligatory for reports.



# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 {
	"Customer<br>Nr" 
	"Project<br>Nr" 
	"Project<br>Name" 
	"Start<br>Date" 
	"End<br>Date"
	"Project<br>Manager" 
	"Invoices"
	"Quotes"
	"Del. Notes"
	"POs"
	"Bills"
	"Expenses"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by project_id \
    header {
	"<a href='$company_url$company_id'>$customer_nr</a>"
	"<a href='$project_url$project_id'>$project_nr</a>"
	$project_name
	$start_date_formatted
	$end_date_formatted
	"<a href='$user_url$project_lead_id'>$project_lead_name</a>"
	$invoices
	$quotes
	$delnotes
	$pos
	$bills
	$expenses
    } \
    content {} \
    footer {} \
]


# Global Footer Line
set footer0 {
	"" 
	"" 
	"" 
	"" 
	""
}


# ------------------------------------------------------------
# Counters
#
# Counters are used to present totals and subtotals.
# This report does not use counters, so the "counters"
# variable is set to an empty list.
#
set counters [list]


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents
#
# Writing out a report can take minutes and hours, so we are
# writing out the HTML contents incrementally to the HTTP 
# connection, allowing the user to read the first lines of the
# report (in particular the help_text) while the rest of the
# report is still being calculated.
#

# Write out the report header with Parameters
# We use simple "input" type of fields for start_date 
# and end_date with default values coming from the input 
# parameters (the "value='...' section).
#

#
ad_return_top_of_page "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='50%'>
		<!-- 'Filters' - Show the Report parameters -->
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td>Start Date:</td>
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
	  <td align=center width='50%'>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
"

# The following report loop is "magic", that means that 
# you don't have to fully understand what it does.
# It loops through all the lines of the SQL statement,
# calls the Report Engine library routines and formats 
# the report according to the report_def definition.

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
set class ""
db_foreach sql $report_sql {

	# Select either "roweven" or "rowodd" from
	# a "hash", depending on the value of "counter".
	# You need explicite evaluation ("expre") in TCL
	# to calculate arithmetic expressions. 
	set class $rowclass([expr $counter % 2])

	# Restrict the length of the project_name to max.
	# 40 characters. (New!)
	set project_name [string_truncate -len 40 $project_name]

	im_report_display_footer \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
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

