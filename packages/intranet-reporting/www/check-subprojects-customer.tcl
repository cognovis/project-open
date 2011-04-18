# /packages/intranet-reporting/www/check-subprojects-customer.tcl
#
# Copyright (c) 2003-2011 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Check if Subprojects have the same company_id as the main project
#

# ------------------------------------------------------------
# Page Contract 
#

ad_page_contract {
    Check if Subprojects have the same company_id as the main project

    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
} {
    { start_date "2001-01-01" }
    { end_date "2099-12-31" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
}


# ------------------------------------------------------------
# Security

set menu_label "reporting-check-subprojects-customer"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# ToDo: Remove
set read_p "t"

if {![string equal "t" $read_p]} {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}


# ------------------------------------------------------------
# Check Parameters
#

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
#

set page_title "Check Subproject's Customers"
set context_bar [im_context_bar $page_title]
set help_text "
	This report checks for inconsistencies in the project structure.<br>
	It lists subprojects, tasks and tickets that have a different<br>
	'customer' then their main project.<br>
	Please press the 'Fix' button to set the sub project's company to<br>
	the one of its parent.<br>
"


# ------------------------------------------------------------
# Default Values and Constants
#
set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set currency_format "999,999,999.09"
set date_format "YYYY-MM-DD"
set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set this_url [export_vars -base "/intranet-reporting/check-subprojects-customer" {start_date end_date} ]
set fix_url "/intranet-reporting/check-subprojects-customer-fix?project_id="
set return_url [im_url_with_query]

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels {2 "Customers" 3 "Customers+Projects"} 


# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.
#


set customer_sql ""
if {0 != $customer_id} {
    set customer_sql "and p.company_id = :customer_id\n"
}

set report_sql "
	select
		parent.project_id as parent_project_id,
		parent.project_name as parent_project_name,
		parent_cust.company_id as parent_company_id,
		parent_cust.company_name as parent_company_name,
		child.project_id as child_project_id,
		child.project_name as child_project_name,
		child_cust.company_id as child_company_id,
		child_cust.company_name as child_company_name
	from
		im_projects parent,
		im_projects child,
		im_companies parent_cust,
		im_companies child_cust
	where
		parent.company_id != child.company_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
		parent.parent_id is null and
		child.parent_id is not null and
		parent.company_id = parent_cust.company_id and
		child.company_id = child_cust.company_id
	order by
		lower(parent_cust.company_path),
		lower(parent.project_name),
		lower(child.project_name)
"

# ------------------------------------------------------------
# Report Definition
#




# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 {
	"Main Project" 
	"Sub Project"
	"Action"
}

set report_def [list \
    group_by parent_project_id \
    header {
	"<a href='$project_url$parent_project_id'>$parent_project_name</a>
	(<a href='$company_url$parent_company_id'>$parent_company_name</a>)"
	"<a href='$project_url$child_project_id'>$child_project_name</a>
	(<a href='$company_url$child_company_id'>$child_company_name</a>)"
	"<a href='$fix_url${child_project_id}&return_url=$return_url' class=button>Fix</a>"
    } \
    content {} \
    footer {} \
]


# Global Footer Line (New!)
set footer0 {
	"" 
	"" 
	""
}


# ------------------------------------------------------------
# Counters
#

set counters [list]


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents
#
ad_return_top_of_page "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='30%'>
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
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
"

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

	im_report_display_footer \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

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


if {0 == $counter} {
    ns_write "
	<tr><td colspan=999 align=center><b>
	[lang::message::lookup "" intranet-reporting.No_inconsistencies_found "No inconsistencies found"]
	</b></td></tr>"
}

ns_write "
	</table>
	[im_footer]
"

