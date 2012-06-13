# /packages/intranet-timesheet2-invoices/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all "delivered" project (i.e. ready to be invoiced).
    Allow the user to select one or more of these projects and
    provide a button to advance to "new-2.tcl".

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(p.project_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @param project_id Allows to skip this page if a single project
           has been select for invoicing. This happens for example,
           if this screen is called from within a project

    @author frank.bergmann@project-open.com
} {
    { order_by "Client" }
    { include_subprojects_p "f" }
    { project_status_id "" } 
    { project_type_id:integer "0" } 
    { project_id "" }
    { company_id "" }
    { target_cost_type_id "" }
    { letter:trim "all" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "invoice_new" }
}

# ---------------------------------------------------------------
# Invoice Creation Page
#
# This is List-Page with some special functions. It consists of the sections:
#    1. Page Contract: 
#	Receive the filter values defined as parameters to this page.
#    2. Defaults & Security:
#	Initialize variables, set default values for filters 
#	(categories) and limit filter values for unprivileged users
#    3. Define Table Columns:
#	Define the table columns that the user can see.
#	Again, restrictions may apply for unprivileged users,
#	for example hiding company names to freelancers.
#    4. Define Filter Categories:
#	Extract from the database the filter categories that
#	are available for a specific user.
#	For example "potential", "invoiced" and "partially paid" 
#	projects are not available for unprivileged users.
#    5. Generate SQL Query
#	Compose the SQL query based on filter criteria.
#	All possible columns are selected from the DB, leaving
#	the selection of the visible columns to the table columns,
#	defined in section 3.
#    6. Format Filter
#    7. Format the List Table Header
#    8. Format Result Data
#    9. Format Table Continuation
#   10. Join Everything Together

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set subproject_types [list "t" "[_ intranet-timesheet2-invoices.Yes]" "f" "[_ intranet-timesheet2-invoices.No]"]
set page_title "[_ intranet-timesheet2-invoices.Invoices]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

set filter_company_id $company_id

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-timesheet2-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-timesheet2-invoices.lt_You_dont_have_suffici]"    
}

set allowed_cost_type [im_cost_type_write_permissions $current_user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}


set letter [string toupper $letter]

if {"" == $target_cost_type_id} { 
    set target_cost_type_id [im_cost_type_invoice] 
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 100]
}
set end_idx [expr $start_idx + $how_many - 1]


# We don't need to show the select screen if only a single project
# has been selected...
if { ![empty_string_p $project_id] && $project_id != 0 } {

    set invoice_currency $default_currency
    ad_returnredirect "/intranet-timesheet2-invoices/invoices/new-2?select_project=$project_id&[export_url_vars target_cost_type_id invoice_currency]"
    set page_body ""
    return
}


# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
set column_headers [list]
set column_vars [list]

set column_sql "
select
	column_name,
	column_render_tcl,
	visible_for
from
	im_view_columns
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"

db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
    }
}



# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
    lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
}
if { ![empty_string_p $project_type_id] && $project_type_id != 0 } {
    # Select the specified project type and its subtypes
    lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
}

if { ![empty_string_p $filter_company_id] && $filter_company_id != 0 } {
    lappend criteria "p.company_id = :filter_company_id"
}


if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "upper(im_first_letter_default_to_a(p.project_name))=:letter"
}
if { $include_subprojects_p == "f" } {

    set main_projects_maxdepth [parameter::get_from_package_key -package_key "intranet-core" -parameter "MainProjectSelectMaxdepth" -default 2]
    if {1 == $main_projects_maxdepth} {
	lappend criteria "p.parent_id is null"
    } else {
	lappend criteria "tree_level(p.tree_sortkey) <= :main_projects_maxdepth"
    }

}


set order_by_clause "order by upper(project_name)"
switch $order_by {
    "Spend Days" { set order_by_clause "order by spend_days" }
    "Estim. Days" { set order_by_clause "order by estim_days" }
    "Start Date" { set order_by_clause "order by start_date" }
    "Delivery Date" { set order_by_clause "order by end_date" }
    "Create" { set order_by_clause "order by create_date" }
    "Quote" { set order_by_clause "order by quote_date" }
    "Open" { set order_by_clause "order by open_date" }
    "Deliver" { set order_by_clause "order by deliver_date" }
    "Close" { set order_by_clause "order by Close_date" }
    "Type" { set order_by_clause "order by project_type" }
    "Status" { set order_by_clause "order by project_status_id" }
    "Delivery Date" { set order_by_clause "order by end_date" }
    "Client" { set order_by_clause "order by company_name" }
    "Words" { set order_by_clause "order by task_words" }
    "Final User" { set order_by_clause "order by final_company" }
    "Project #" { set order_by_clause "order by project_nr" }
    "Project Manager" { set order_by_clause "order by upper(lead_name)" }
    "URL" { set order_by_clause "order by upper(url)" }
    "Project Name" { set order_by_clause "order by lower(project_name)" }
    "Project_Name" { set order_by_clause "order by lower(project_name)" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# Invoices: We're only looking for projects with non-invoiced tasks.
# Quotes: We're looking basically for all projects that satisfy the 
# filter conditions
set task_invoice_id_null ""

# fraber 080215: Now going for the included hours and not the tasks anymore
# if {$target_cost_type_id == [im_cost_type_invoice]} {
#     set task_invoice_id_null "and invoice_id is null"
# }


set sql "
select 
	p.project_id,
	p.project_name,
        p.project_nr,
        p.project_path,
        p.project_lead_id,
        p.company_id,
        c.company_name,
	im_name_from_user_id(p.project_lead_id) as lead_name,
        im_category_from_id(p.project_type_id) as project_type, 
        im_category_from_id(p.project_status_id) as project_status,
	p.start_date,
	to_char(p.end_date, 'YYYY-MM-DD') as end_date,
	to_char(end_date, 'HH24:MI') as end_date_time
from 
	im_projects p, 
        im_companies c,
	(select project_id,
		count(*) as task_count 
	 from	im_timesheet_tasks_view 
	 where	1=1 $task_invoice_id_null
	 group by project_id
	) t
where 
	p.project_id = t.project_id
	and t.task_count > 0
        and c.company_id=p.company_id
	$where_clause
	$order_by_clause
"


# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites
#
if {[string compare $letter "ALL"]} {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection "$sql"
} else {
    set limited_query [im_select_row_range $sql $start_idx $end_idx]
    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string projects_total_in_limited "
	select count(*) 
        from im_projects p 
        where 1=1 $where_clause"]

    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "new?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    set col_txt [lang::util::suggest_key $col]
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>[_ intranet-timesheet2-invoices.$col_txt]</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">[_ intranet-timesheet2-invoices.$col_txt]</a></td>\n"
    }
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 1
set idx $start_idx
set old_company_name ""
db_foreach projects_info_query $selection {

    # insert intermediate headers for every company if the list is sorted by company.
    if {[string equal $order_by "Client"] && ![string equal $company_name $old_company_name] } {
	append table_body_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	set old_company_name $company_name
    }

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
	eval $cmd
	append table_body_html "</td>\n"
    }
    append table_body_html "</tr>\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        [_ intranet-timesheet2-invoices.lt_There_are_currently_n_1]
        </b></ul></td></tr>"
}


if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
    set next_page_url "new?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}


if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "new?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

# Check if there are rows that we decided not to return
# => include a link to go to the next page 
#
if {$ctr==$how_many && $total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr $end_idx + 1]
    set next_page "<a href=new?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-timesheet2-invoices.Next_Page]</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the 
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=new?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-timesheet2-invoices.Previous_Page]</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

set submit_button "
      <tr>
        <td colspan=$colspan align=right>
	   [_ intranet-timesheet2-invoices.Invoice_Currency]: [im_currency_select invoice_currency $default_currency]
	   <input type=submit value='[_ intranet-timesheet2-invoices.lt_Select_Projects_for_I]'> 
        </td>
      </tr>
"


# ---------------------------------------------------------------
# Join all parts together
# ---------------------------------------------------------------

set company_id $filter_company_id

set costs_navbar_html [im_costs_navbar $letter "/intranet-timesheet2-invoices/invoices/new" $next_page_url $previous_page_url [list project_status_id target_cost_type_id project_type_id company_id start_idx order_by how_many mine_p view_name letter include_subprojects_p] ""]

set admin_html ""


# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            #intranet-core.Filter_Projects#
         </div>
	<table>
	<tr>
	  <td>
		<form method=GET action='/intranet-timesheet2-invoices/invoices/new'>
		[export_form_vars start_idx order_by how_many target_cost_type_id view_name include_subprojects_p letter]
		<table border=0 cellpadding=0 cellspacing=0>
		<tr>
		  <td valign=top>
[lang::message::lookup "" intranet-timesheet2-invoices.Project_br_Status "Project<br>Status"]:
    		  </td>
		  <td valign=top>[im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id $project_status_id]</td>
		</tr>

		<tr>
		  <td valign=top>
		  [lang::message::lookup "" intranet-timesheet2-invoices.Project_br_Type "Project<br>Type"]:
		  </td>
		  <td valign=top>
		    [im_category_select -include_empty_p 1 "Intranet Project Type" project_type_id $project_type_id]
		  </td>
		</tr>

		<tr>
		  <td valign=top>
		      [lang::message::lookup "" intranet-core.Customer "Customer"]:
		  </td>
		  <td valign=top>
		      [im_company_select -include_empty_p 1 -include_empty_name "All" company_id $filter_company_id "" "CustOrIntl"]
		  </td>
		</tr>

		<tr>
		  <td valign=top>&nbsp;</td>
		  <td valign=top>
			  <input type=submit value=Go name=submit>
		  </td>
		</tr>

		</table>
		</form>
	  </td>
	</tr>
	<tr>
	  <td>#intranet-timesheet2-invoices.lt_To_create_a_new_invoi#</td>
	</tr>
	</table>
      </div>
"