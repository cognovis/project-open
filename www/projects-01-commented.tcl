# /packages/intranet-reporting-tutorial/www/projects-01.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Projects-01 Tutorial Contents
#
# This report contains:
#
# - Page Title, Bread Crums and Help
# - Report SQL (base)
# - Report Definition (base)
# - Render Report Header
# - Render Report Body
# - Render Report Footer
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

set page_title "Projects-01-Commented Tutorial Report"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Projects-01-Commented Tutorial Report:</strong><br>
	This is the first report of the Reporting Tutorial.
	The report shows all 'main' projects in the system.
	Please see the <a href=\"source?source=projects-01-commented\">source code</a> for details.
"


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
		p.*
	from
		im_projects p
	where
		parent_id is null
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
#	where
#		parent_id is null
#
# "parent_id" indicates the project's parent project.
# So this clause eliminates any subprojects from the list.
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
	"Start Date" 
	"End Date"
}

set report_def [list \
    group_by project_id \
    header {
	$project_nr
	$project_name
	$start_date
	$end_date
    } \
    content {} \
    footer {} \
]

# Level of Details
# Will be used more extensively with groupings
#
set level_of_detail 1

# Diplay report lines using CSS style "rowodd"
set class "rowodd"




# ------------------------------------------------------------
# Counters
#
# Counters are used to present totals and subtotals.
# This report does not use counters, so the "counters"
# variable is set to an empty list.
#
set counters [list]


# ------------------------------------------------------------
# Render Report Header
#
# Writing out a report can take minutes and hours, so we are
# writing out the HTML contents incrementally to the HTTP 
# connection, allowing the user to read the first lines of the
# report (in particular the help_text) while the rest of the
# report is still being calculated.
#

# Write out the report header
#
ad_return_top_of_page "
	<!-- Write out the logo stuff and the user info -->
	[im_header]
	<!-- Write out the main system navigation bar -->
	[im_navbar]
	<!-- Write out the help text. -->
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='50%'>
		<!-- 'Filters' -->
	  </td>
	  <td align=center width='50%'>
		<!-- Help Text -->
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

# ------------------------------------------------------------
# Render Report Body

# The following report loop is "magic", that means that 
# you don't have to fully understand what it does.
# It loops through all the lines of the SQL statement,
# calls the Report Engine library routines and formats 
# the report according to the report_def definition.

# Start <magic>

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

db_foreach sql $report_sql {
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
}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

# End </magic>


# ------------------------------------------------------------
# Render Report Footer

# Write out the HTMl to close the main report table
# and write out the page footer.
#
ns_write "
	</table>
	[im_footer]
"

