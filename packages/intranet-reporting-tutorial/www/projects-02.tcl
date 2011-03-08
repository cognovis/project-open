# /packages/intranet-reporting-tutorial/www/projects-02.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Projects-02 Tutorial Contents
#
# This report contains everything from projects-01 plus
# some new features. Search for "New!" for the new stuff:
#
# - Page Contract
# - Simple Parameters
# - Even/Odd line formatting
# - Simple SQL value formatting
# - Global Footer Line
# - im_name_from_user_id function



#
# Does not yet contain:
# - Category based parameters with drop-down
# - Custom parameters with drop-down
# - Parameter value checks
# - Security
# - Level of details
# - Grouping
# - Grand Totals
# - Subtotals
# - Simple Joins
# - Left Outer Joins
# - Calculated variables
# - Localized Strings
# - Localized Date & Number & Currencies
# - Drill-down
#


# ------------------------------------------------------------
# Page Contract (New!)
#
# This section give some comments about the page for the 
# automatic documentation function and defines parameters 
# with their default values.
# You can overwrite the default values by specifying the
# parameters in the URL, for example:
# http://your_server/intranet-reporting-tutorial/ ...
# ... /projects-02?start_date=2006-01-01&end_date=2006-12-31
#

ad_page_contract {
    Reporting Tutorial "projects-02" Report
    This reports lists all projects in a time interval
    It is one of the easiest reports imaginable...

    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
} {
    { start_date "2005-01-01" }
    { end_date "2099-12-31" }
}


# ------------------------------------------------------------
# Security
#
# No security yet - Everybody can see the report if he or she
# knows that URL of the report.
#


# ------------------------------------------------------------
# Check Parameters
#
# No parameter check yet - Bad parameters values will dead to
# an "ugly" error message, as opposed to an error message
# identifying the bad parameters.
#


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

set page_title "Projects-02 Tutorial Report"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Projects-02 Tutorial Report:</strong><br>
	This is the second reports of the Reporting Tutorial.
	The report shows all projects if their end_date is inside
	the interval between start_date and end_date, including
	the start_date, but excluding the end_date.
	The interval defaults to 2000-01-01 - 2100-01-01.
	Please see the <a href=\"source?source=projects-02\">source code</a> for details.
"


# ------------------------------------------------------------
# Default Values and Constants
#
# In this section we define constants and default variables
# that are used in the sections further below.
#

# Default report line formatting - alternating between the
# CSS styles "roweven" (grey) and "rowodd" (lighter grey).
# (New!)
#
set rowclass(0) "roweven"
set rowclass(1) "rowodd"

# Variable formatting - Default formatting is quite ugly
# normally. In the future we will include locale specific
# formatting. (New!)
#
set currency_format "999,999,999.09"
set date_format "YYYY-MM-DD"

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

set report_sql "
	select
		p.*,
		to_char(p.start_date, :date_format) as start_date_formatted,
		to_char(p.end_date, :date_format) as end_date_formatted,
		im_name_from_user_id(p.project_lead_id) as project_manager_name
	from
		im_projects p
	where
		parent_id is null
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
#		im_name_from_user_id(p.project_lead_id) as project_manager_name
#
# These lines demonstrate some basic formatting applied to
# table fields: (New!)
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
# "$start_date") by the moment of dereferentiation. (New!)
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
	"Project Nr" 
	"Project Name" 
	"Project Manager" 
	"Start Date" 
	"End Date"
}

set report_def [list \
    group_by project_id \
    header {
	$project_nr
	$project_name
	$project_manager_name
	$start_date_formatted
	$end_date_formatted
    } \
    content {} \
    footer {} \
]


# Global Footer Line (New!)
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

# Write out the report header with Parameters (New!)
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
	# to calculate arithmetic expressions. (New!)
	set class $rowclass([expr $counter % 2])

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

