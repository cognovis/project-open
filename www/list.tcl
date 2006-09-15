# /packages/intranet-cost/www/list.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all costs together with their payments

    @param company_id Either customer or provide, when the calling
           side doesn't know

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Name" }
    { cost_status_id:integer 0 } 
    { cost_type_id:integer 0 } 
    { customer_id:integer 0 } 
    { provider_id:integer 0 } 
    { project_id:integer 0 }
    { company_id:integer 0 } 
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "cost_list" }
    { view_mode "view" }
}

# ---------------------------------------------------------------
# Cost List Page
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
#	For example "potential" and "partially paid" 
#	costs are not available for unprivileged users.
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
set page_title "[_ intranet-cost.Cost_Items]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"
set cur_format "99,999.99"
set local_url "list"
set date_format "YYYY-MM-DD"

if {![im_permission $user_id view_costs]} {
    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
    return
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
}
set end_idx [expr $start_idx + $how_many - 1]

if {0 != $project_id && "" != $project_id} {
    set company_id [db_string company_from_project "select company_id from im_projects where project_id = :project_id" -default 0]
}


# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id} { ad_return_complaint 1 "<li>[_ intranet-cost.lt_Didnt_find_the_the_vi]"}
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
	regsub -all " " $column_name "_" column_key
	lappend column_headers "[_ intranet-cost.$column_key]"
	lappend column_vars "$column_render_tcl"
    }
}

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $cost_status_id] && $cost_status_id > 0 } {
    lappend criteria "c.cost_status_id=:cost_status_id"
}
if { ![empty_string_p $cost_type_id] && $cost_type_id != 0 } {
    lappend criteria "c.cost_type_id in (
		select distinct h.child_id
		from	im_category_hierarchy h
		where	(h.child_id = :cost_type_id or h.parent_id = :cost_type_id)
	)"
}
if {$customer_id} {
    lappend criteria "c.customer_id=:customer_id"
}
if {$provider_id} {
    lappend criteria "c.provider_id=:provider_id"
}
if {$company_id} {
    lappend criteria "(c.provider_id = :company_id OR c.customer_id = :company_id)"
}
if {"" != $project_id && 0 != $project_id} {
    lappend criteria "c.cost_id in (
	select distinct cost_id
	from im_costs
	where project_id=:project_id
    UNION
	select distinct cost_id
	from im_costs
	where parent_id = :project_id
    UNION
	select distinct object_id_two as cost_id
	from acs_rels
	where object_id_one = :project_id
    UNION
	select distinct object_id_two as cost_id
	from acs_rels r, im_projects p
	where object_id_one = p.project_id
	      and p.parent_id = :project_id
    )"
}



if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(cust.company_name)=:letter"
}


# Get the list of user's companies for which he can see costs
set company_ids [db_list users_companies "
select
	c.company_id
from
	acs_rels r,
	im_companies c
where
	r.object_id_two = :user_id
	and r.object_id_one = c.company_id
"]

lappend company_ids 0

# Determine which costs the user can see.
# Normally only those of his/her company...
# Special users ("view_costs") don't need permissions.
set company_where ""
if {![im_permission $user_id view_costs]} { 
    set company_where "and (c.customer_id in ([join $company_ids ","]) or c.provider_id in ([join $company_ids ","]))"
}
ns_log Notice "/intranet-cost/index: company_where=$company_where"


set order_by_clause ""
switch $order_by {
    "Name" { set order_by_clause "order by cost_name DESC" }
    "Type" { set order_by_clause "order by cost_type" }
    "Project" { set order_by_clause "order by project_nr" }
    "Provider" { set order_by_clause "order by prov.company_name" }
    "Client" { set order_by_clause "order by cust.company_name" }
    "Due Date" { set order_by_clause "order by due_date_calculated" }
    "Amount" { set order_by_clause "order by c.amount DESC" }
    "Paid" { set order_by_clause "order by paid_amount" }
    "Status" { set order_by_clause "order by cost_status_id" }
}

set where_clause [join $criteria " and\n	    "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

# -----------------------------------------------------------------
# Define extra SQL for payments
# -----------------------------------------------------------------

set payment_amount ""
set payment_currency ""

set extra_select ""
set extra_from ""
set extra_where ""

set total_in_limited -1
set how_many -1

# ---------------------------------------------------------------
# 6a. Format the Filter: Get the admin menu
# ---------------------------------------------------------------

set new_document_menu ""
set parent_menu_label "costs"

if {"" != $parent_menu_label} {
    set parent_menu_sql "select menu_id from im_menus where label=:parent_menu_label"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default ""]

    set menu_select_sql "
	select  m.*
	from    im_menus m
	where   parent_menu_id = :parent_menu_id
		and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
	order by sort_order"

    # Start formatting the menu bar
    set new_document_menu ""
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	
	ns_log Notice "im_sub_navbar: menu_name='$name'"
	regsub -all " " $name "_" name_key
	append new_document_menu "<li><a href=\"$url\">[_ intranet-cost.$name_key]</a></li>\n"
    }
}

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options
set filter_html "

<table>
<tr valign=top>
  <td valign=top>

	<form method=get action='/intranet-cost/list'>
	[export_form_vars start_idx order_by how_many view_name include_subcosts_p letter]
	<table border=0 cellpadding=1 cellspacing=1>
	  <tr> 
	    <td colspan='2' class=rowtitle align=center>
	      [_ intranet-cost.Filter_Documents]
	    </td>
	  </tr>
	  <tr>
	    <td>[_ intranet-cost.Document_Status]:</td>
	    <td>
	      [im_category_select -include_empty_p 1 "Intranet Cost Status" cost_status_id $cost_status_id]
	    </td>
	  </tr>
	  <tr>
	    <td>[_ intranet-cost.Document_Type]:</td>
	    <td>
	      [im_category_select -include_empty_p 1 "Intranet Cost Type" cost_type_id $cost_type_id]
	      <input type=submit value='[_ intranet-cost.Go]' name=submit>
	    </td>
	  </tr>
	</table>
	</form>

  </td>
  <td valign=top>&nbsp;</td>
  <td valign=top>

	<table border=0 cellpadding=1 cellspacing=1>
	  <tr> 
	    <td colspan='2' class=rowtitle align=center>
	      [_ intranet-cost.lt_Cost_Item_Administrat]
	    </td>
	  </tr>
	  <tr>
	    <td colspan=2 valign=top>
	      <ul>
		$new_document_menu
	      </ul>
	    </td>
	  </tr>
	</table>
	
  </td>
</tr>
</table>
"

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""
#<tr>
#  <td align=center valign=top colspan=$colspan><font size=-1>
#    [im_groups_alpha_bar [im_cost_group_id] $letter "start_idx"]</font>
#  </td>
#</tr>"

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "$local_url?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></td>\n"
    }
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
db_foreach costs_info_query {} {
    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # set currency to NULL if amount was null...
    if {"" == $amount} { set currency "" }

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
	[_ intranet-cost.lt_There_are_currently_n]
	</b></ul></td></tr>"
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
    set next_page_url "$local_url?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "$local_url?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
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
    set next_page "<a href=$local_url?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-cost.Next_Page]</a>"
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
    set previous_page "<a href=$local_url?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-cost.Previous_Page]</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

set button_html "
<tr>
  <td colspan=[expr $colspan - 3]></td>
  <td align=center>
    <input type=submit name=submit_save value='[_ intranet-cost.Save]'>
  </td>
  <td align=center>
    <input type=submit name=submit_del value='[_ intranet-cost.Del]'>
  </td>
</tr>"

# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

set page_body "
$filter_html
[im_costs_navbar $letter "/intranet-cost/list" $next_page_url $previous_page_url [list cost_status_id cost_type_id company_id start_idx order_by how_many view_name letter] "<#_ costs#>"]

<form action=/intranet-cost/costs/cost-action method=POST>
[export_form_vars company_id cost_id return_url]
  <table width=100% cellpadding=2 cellspacing=2 border=0>
    $table_header_html
    $table_body_html
    $table_continuation_html
    $button_html
  </table>
</form>

"

db_release_unused_handles

#doc_return  200 text/html [im_return_template]
