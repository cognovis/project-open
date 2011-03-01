# /packages/intranet-reporting-tutorial/www/projects-01-few-comments.tcl
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

set page_title "Projects-01-Few-Comments Tutorial Report"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Projects-01-Few-Comments Tutorial Report:</strong><br>
	This is the first report of the Reporting Tutorial.
	The report shows all 'main' projects in the system.
"

# ------------------------------------------------------------
# Report SQL

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

# ------------------------------------------------------------
# Report Definition

# Report Global Header Line
set header0 {
	"Project Nr" 
	"Project Name" 
	"Start Date" 
	"End Date"
}

# Report Body
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

# No counters (subtotals, ...)
set counters [list]

# Diplay report lines using CSS style "rowodd"
set class "rowodd"

# Show all details for this report (no grouping)
set level_of_detail 1


# ------------------------------------------------------------
# Render Report Header

ad_return_top_of_page "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='50%'><!-- Filters --></td>
	  <td align=center width='50%'>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	<table border=0 cellspacing=1 cellpadding=1>
"

# ------------------------------------------------------------
# Render Report Body

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


# ------------------------------------------------------------
# Render Report Footer

ns_write "
	</table>
	[im_footer]
"
