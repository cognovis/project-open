# /packages/intranet-payments/www/index.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all payments together with their payments

    @param order_by payment display order 
    @param include_subpayments_p whether to include sub payments
    @param status_id criteria for payment status
    @param type_id criteria for payment_type_id
    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Client" }
    { letter:trim "" }
    { status_id:integer 0 }
    { type_id:integer 0 }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "payment_list" }
}

# ---------------------------------------------------------------
# Payment List Page
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
#	For example "potential", "paymentd" and "partially paid" 
#	payments are not available for unprivileged users.
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
set page_title "[_ intranet-payments.Payments]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"

if {![im_permission $user_id view_payments]} {
    ad_return_complaint "[_ intranet-payments.lt_Insufficient_Privileg]" "
    <li>[_ intranet-payments.lt_You_dont_have_suffici]"    
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
}
set end_idx [expr $start_idx + $how_many - 1]


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
# 4. Define Filter Categories
# ---------------------------------------------------------------

# type_types will be a list of pairs of (payment_type_id, payment_type)
set type_types [im_memoize_list select_payment_type_types \
        "select payment_type_id, payment_type
         from im_payment_type
         order by lower(payment_type)"]

# No "All" type, because we _really_ don't want to show the
# "In Process" payments left over from the creation process.
#
#set type_types [linsert $type_types 0 0 All]

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $status_id] && $status_id > 0 } {
    lappend criteria "p.payment_status_id=:status_id"
}
if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.payment_type_id=:type_id"
}
if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(ug.group_name)=:letter"
}

set order_by_clause ""
switch $order_by {
    "Client" { set order_by_clause "order by company_name" }
    "Invoice" { set order_by_clause "order by ci.cost_name DESC" }
    "Payment #" { set order_by_clause "order by payment_id DESC" }
    "Received" { set order_by_clause "order by received_date DESC" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

# ToDo: Slow query with the number of costs

set sql "
select
        p.*,
        to_char(p.received_date,'YYYY-MM-DD') as received_date,
	p.amount as payment_amount,
	p.currency as payment_currency,
	ci.customer_id,
	ci.amount as cost_amount,
	ci.currency as cost_currency,
	ci.cost_name,
	acs_object.name(ci.customer_id) as company_name,
        im_category_from_id(p.payment_type_id) as payment_type,
        im_category_from_id(p.payment_status_id) as payment_status
from
        im_payments p,
	im_costs ci
where
	p.cost_id = ci.cost_id
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
    set total_in_limited [db_string payments_total_in_limited "
	select count(*) 
        from im_payments p, user_groups ug 
        where p.group_id=ug.group_id $where_clause"]

    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options
set filter_html "

<table>
<tr>
  <td>
	<form method=get action='/intranet-cost/index'>
	[export_form_vars start_idx order_by how_many view_name include_subpayments_p letter]
	<table border=0 cellpadding=0 cellspacing=0>
	  <tr> 
	    <td colspan='2' class=rowtitle align=center>
	      [_ intranet-payments.Filter_Payments]
	    </td>
	  </tr>
	  <tr>
	    <td valign=top>[_ intranet-payments.Payment_Status]</td>
	    <td valign=top>
              [im_select -translate_p 0 status_id $type_types ""]
              <input type=submit value='[_ intranet-payments.Go]' name=submit>
            </td>
	  </tr>
	</table>
	</form>
  </td>
  <td>
	<table><tr>
	  <td>
	    <blockquote>
		&nbsp;
	    <blockquote>
	  </td>
	</tr></table>
	
  </td>
</tr></table>
"

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    regsub -all " " $col "_" col_key
    regsub -all "#" $col_key "hash_simbol" col_key
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>[_ intranet-payments.$col_key]</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">[_ intranet-payments.$col_key]</a></td>\n"
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
db_foreach payments_info_query $selection {
    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
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
        [_ intranet-payments.lt_There_are_currently_n]
        </b></ul></td></tr>"
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
    set next_page_url "index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 1 }
    set previous_page_url "index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
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
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-payments.Next_Page]</a>"
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
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-payments._Previous]</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

#$filter_html

set page_body "
[im_costs_navbar $letter "/intranet-payments/index" $next_page_url $previous_page_url [list status_id type_id start_idx order_by how_many view_name letter] "payments_list"]

<form action=payment-action method=POST>
[export_form_vars company_id payment_id return_url]
  <table width=100% cellpadding=2 cellspacing=2 border=0>
    $table_header_html
    $table_body_html
    $table_continuation_html
<tr>
  <td colspan=$colspan align=right>
    <input type=submit name=submit value='Add New'>
    <input type=submit name=submit value='Del'>
  </td>
</tr>

  </table>
</form>

"

db_release_unused_handles

#doc_return  200 text/html [im_return_template]
