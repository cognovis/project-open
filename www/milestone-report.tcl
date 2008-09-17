# /packages/intranet-milestone/www/index.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Projects-05 Tutorial Contents
#
# This report contains everything from projects-01 plus
# some new features. Search for "New!" for the new stuff:
#
# - Grouping
# - Level of details
# - Counters (Subtotal)
# - Drill-down
# - Calculated variables
# - Parameter value checks


#
# Does not yet contain:
#
# - Custom parameters with drop-down
# - Category based parameters with drop-down
# - Left Outer Joins
# - Localized Date & Number & Currencies
# - Changing sorting and sort direction


# ------------------------------------------------------------
# Page Contract 
#
# This section give some comments about the page for the 
# automatic documentation function and defines parameters 
# with their default values.
# You can overwrite the default values by specifying the
# parameters in the URL, for example:
# http://your_server/intranet-reporting-tutorial/ ...
# ... /projects-05?start_date=2006-01-01&end_date=2006-12-31
#

ad_page_contract {
    Reporting Tutorial "projects-05" Report
    This reports lists all projects in a time interval
    It is one of the easiest reports imaginable...

    @param start_date Start date (YYYY-MM-DD format) 
    @param end_date End date (YYYY-MM-DD format) 
} {
    { start_date "2005-01-01" }
    { end_date "2099-12-31" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
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
set menu_label "reporting-tutorial-projects-05"

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

# Maxlevel is 3. 
if {$level_of_detail > 3} { set level_of_detail 3 }



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

set page_title "Projects-05 Tutorial Report"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Projects-05 Tutorial Report:</strong><br>
	This is the third reports of the Reporting Tutorial.
	The report shows all projects if their end_date is inside
	the interval between start_date and end_date, including
	the start_date, but excluding the end_date.
	The interval defaults to 2000-01-01 - 2100-01-01.
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
set this_url [export_vars -base "/intranet-reporting-tutorial/projects-05" {start_date end_date} ]

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels {2 "Customers" 3 "Customers+Projects"} 



# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.
#
# This section is usually the starting point when starting 
# any new report.
# Once your SQL is fine you you start adding formatting, 
# grouping and filters to create a "real-world" report.
#

set customer_sql ""
if {0 != $customer_id} {
    set customer_sql "and p.company_id = :customer_id\n"
}

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
		cust.company_id as customer_id,
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
		$customer_sql
	order by
		lower(cust.company_path),
		lower(p.project_nr)
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
	"Cust" 
	"Project<br>Nr" 
	"Project<br>Name" 
	"Project<br>Manager" 
	"Invoices"
	"Quotes"
	"Del.<br>Notes"
	"POs"
	"Bills"
	"Expenses"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by customer_id \
    header {
	"\#colspan=10 <a href=$this_url&customer_id=$customer_id&level_of_detail=4 
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
			$invoices
			$quotes
			$delnotes
			$pos
			$bills
			$expenses
		    } \
		    content {} \
	    ] \
            footer {} \
    ] \
    footer {  
		""
		""
		""
		""
		"<nobr><i>$invoice_subtotal</i></nobr>" 
		"<nobr><i>$quote_subtotal</i></nobr>" 
		"<nobr><i>$delnote_subtotal</i></nobr>" 
		"<nobr><i>$bill_subtotal</i></nobr>" 
		"<nobr><i>$po_subtotal</i></nobr>"
		"<nobr><i>$expense_subtotal</i></nobr>"
    } \
]


set ttt {
		"<nobr><i>$po_per_quote_perc</i></nobr>"
		"<nobr><i>$gross_profit</i></nobr>"
}


# Global Footer Line
set footer0 {
	"" 
	"" 
	""
        "<br><b>Total:</b>"
	"<br><b>$invoice_total</b>"
	"<br><b>$quote_total</b>"
	"<br><b>$delnote_total</b>"
	"<br><b>$po_total</b>"
	"<br><b>$bill_total</b>"
	"<br><b>$expense_total</b>"
}


# ------------------------------------------------------------
# Counters (New!)
#
# Counters are used to present totals and subtotals.
# Counters consist of several parts:
#	- A "pretty_name"
#	- A "var" variable. This variable can be used
#	  in the report to refer to the value of the counter.
#	- A "reset" condition. 
#	  The value of the counter will be reset to 0
#	  every time the value of this expression _changes_.
#	  This allows to define several levels of counters.
#	- An "expr" expression that is to be evaluated.
#
# The counters are updated inside the Main Report Loop with
# variables from the SQL query.
#
# Please note the "+0" part in all the counters. This is
# a trick to deal with possible null (empty) values of the
# numeric fields. In this case the "+0" is just evaluated
# to "0".

#
# Subtotal Counters (per project)
#
set invoice_subtotal_counter [list \
        pretty_name "Invoice Amount" \
        var invoice_subtotal \
        reset \$customer_id \
        expr "\$cost_invoices_cache+0" \
]

set quote_subtotal_counter [list \
        pretty_name "Quote Amount" \
        var quote_subtotal \
        reset \$customer_id \
        expr "\$cost_quotes_cache+0" \
]

set delnote_subtotal_counter [list \
        pretty_name "Delnote Amount" \
        var delnote_subtotal \
        reset \$customer_id \
        expr "\$cost_delivery_notes_cache+0" \
]

set bill_subtotal_counter [list \
        pretty_name "Bill Amount" \
        var bill_subtotal \
        reset \$customer_id \
        expr "\$cost_bills_cache+0" \
]

set expense_subtotal_counter [list \
        pretty_name "Expense Amount" \
        var expense_subtotal \
        reset \$customer_id \
        expr "\$cost_expense_logged_cache+0" \
]

set po_subtotal_counter [list \
        pretty_name "Po Amount" \
        var po_subtotal \
        reset \$customer_id \
        expr "\$cost_purchase_orders_cache+0" \
]

#
# Grand Total Counters
#
set invoice_grand_total_counter [list \
        pretty_name "Invoice Amount" \
        var invoice_total \
        reset 0 \
        expr "\$cost_invoices_cache+0" \
]

set quote_grand_total_counter [list \
        pretty_name "Quote Amount" \
        var quote_total \
        reset 0 \
        expr "\$cost_quotes_cache+0" \
]

set delnote_grand_total_counter [list \
        pretty_name "Delnote Amount" \
        var delnote_total \
        reset 0 \
        expr "\$cost_delivery_notes_cache+0" \
]

set bill_grand_total_counter [list \
        pretty_name "Bill Amount" \
        var bill_total \
        reset 0 \
        expr "\$cost_bills_cache+0" \
]

set expense_grand_total_counter [list \
        pretty_name "Expense Amount" \
        var expense_total \
        reset 0 \
        expr "\$cost_expense_logged_cache+0" \
]

set po_grand_total_counter [list \
        pretty_name "Po Amount" \
        var po_total \
        reset 0 \
        expr "\$cost_purchase_orders_cache+0" \
]




set counters [list \
	$invoice_subtotal_counter \
	$quote_subtotal_counter \
	$delnote_subtotal_counter \
	$bill_subtotal_counter \
	$expense_subtotal_counter \
	$po_subtotal_counter \
	$invoice_grand_total_counter \
	$quote_grand_total_counter \
	$delnote_grand_total_counter \
	$bill_grand_total_counter \
	$expense_grand_total_counter \
	$po_grand_total_counter \
]

# Set the values to 0 as default (New!)
set invoice_total 0
set quote_total 0
set delnote_total 0
set bill_total 0
set po_total 0
set expense_total 0


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

	im_report_update_counters -counters $counters

	# Calculated Variables (New!)
	set po_per_quote_perc "undef"
	if {[expr $quote_subtotal+0] != 0} {
	  set po_per_quote_perc [expr int(10000.0 * $po_subtotal / $quote_subtotal) / 100.0]
	  set po_per_quote_perc "$po_per_quote_perc %"
	}
	set gross_profit [expr $invoice_subtotal - $bill_subtotal]

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

