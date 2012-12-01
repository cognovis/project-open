# /packages/intranet-invoices/www/list.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all invoices together with their payments

    @param order_by invoice display order 
    @param include_subinvoices_p whether to include sub invoices
    @param cost_status_id criteria for invoice status
    @param cost_type_id criteria for cost_type_id
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Document #" }
    { cost_status_id:integer "[im_cost_status_created]" } 
    { cost_type_id:integer 0 } 
    { company_id:integer 0 } 
    { provider_id:integer 0 } 
    { start_date "" }
    { end_date "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "" }
    { view_type "" }
    { letter:trim "" }
}

# ---------------------------------------------------------------
# Invoice List Page
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
#	invoices are not available for unprivileged users.
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
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "[_ intranet-invoices.Financial_Documents]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set local_url "/intranet-invoices/list"
set cost_status_created [im_cost_status_created]
set cost_type [db_string get_cost_type "select category from im_categories where category_id=:cost_type_id" -default [_ intranet-invoices.Costs]]

# Support for OpenOffice 
if {"" == $view_type} {
    set letter [string toupper $letter]
} else {
    set letter "ALL"
    set start_idx 0
    set how_many 100000000
}

if {![im_permission $user_id view_invoices]} {
    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
    return
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage  "" 50]
}
set end_idx [expr $start_idx + $how_many]


if {"" == $start_date} { set start_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultStartDate -default "2000-01-01"] }
if {"" == $end_date} { set end_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultEndDate -default "2100-01-01"] }

# Find out if we are looking at customers or providers

set new_document_menu ""
set parent_menu_label ""
if {$cost_type_id == [im_cost_type_company_doc] || [im_category_is_a $cost_type_id [im_cost_type_company_doc]]} {
    set parent_menu_label "invoices_customers"
}
if {$cost_type_id == [im_cost_type_provider_doc] || [im_category_is_a $cost_type_id [im_cost_type_provider_doc]]} {
    set parent_menu_label "invoices_providers"
}

# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#

if {"" == $view_name} {
    # Set the default view_name but overwrite in case we have
    # customers or providers
    set view_name "invoice_list"
    if {$cost_type_id == [im_cost_type_company_doc] || [im_category_is_a $cost_type_id [im_cost_type_company_doc]]} {
	set view_name "invoice_customer_list"
    }
    if {$cost_type_id == [im_cost_type_provider_doc] || [im_category_is_a $cost_type_id [im_cost_type_provider_doc]]} {
	set view_name "invoice_provider_list"
    }
}

set view_id [db_string get_view_id "
	select view_id 
	from im_views 
	where view_name = :view_name
" -default 0
]

if {0 == $view_id} {
    ad_return_complaint 1 "<b>View not found</b>:<br>
    We have got a 0 value for view=$view_id,
    indicating that this view has not been set up yet.<br>
    Please make sure to update to a recent version and to 
    apply the database update patches."
    return
}


set column_sql "
select	column_name,
	column_render_tcl,
	visible_for,
        extra_select
from	im_view_columns
where	view_id = :view_id
	and group_id is null
order by
	sort_order"

# Get the main view
set column_headers [list]
set column_vars [list]
set extra_select_sql ""
db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	if {"" != $extra_select} {
	    append extra_select_sql ",$extra_select"
	}
    }
}


# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $cost_status_id] && $cost_status_id > 0 } {
    lappend criteria "i.cost_status_id in ([join [im_sub_categories $cost_status_id] ","])"
}

if { ![empty_string_p $cost_type_id] && $cost_type_id != 0 } {
    lappend criteria "i.cost_type_id in ([join [im_sub_categories $cost_type_id] ","])"
}
if { ![empty_string_p $company_id] && $company_id != 0 } {
    lappend criteria "(i.customer_id = :company_id OR i.provider_id = :company_id)"
}
if { ![empty_string_p $provider_id] && $provider_id != 0 } {
    lappend criteria "i.provider_id=:provider_id"
}
if {"" != $start_date} {
    lappend criteria "i.effective_date >= :start_date::timestamptz"
}
if {"" != $end_date} {
    lappend criteria "i.effective_date < :end_date::timestamptz"
}



# Get the list of user's companies for which he can see invoices
set company_ids [db_list users_companies "
select
	company_id
from
	acs_rels r,
	im_companies c
where
	r.object_id_two = :user_id
	and r.object_id_one = c.company_id
"]

lappend company_ids 0

# Determine which invoices the user can see.
# Normally only those of his/her company...
# Special users ("view_invoices") don't need permissions.
set company_where ""
if {![im_permission $user_id view_invoices]} { 
    set company_where "and (i.customer_id in ([join $company_ids ","]) or i.provider_id in ([join $company_ids ","]))"
}
ns_log Notice "/intranet-invoices/index: company_where=$company_where"

set counter_reset_expression ""
set order_by_clause ""
switch $order_by {
    "Document #" { 
	set order_by_clause "order by invoice_nr DESC" 
	set counter_reset_expression {$effective_month}
    }
    "Preview" { 
	set order_by_clause "order by invoice_nr" 
    }
    "Provider" { 
	set order_by_clause "order by provider_name" 
	set counter_reset_expression {$provider_id}
    }
    "Customer" { 
	set order_by_clause "order by customer_name" 
	set counter_reset_expression {$customer_id}
    }
    "Due Date" { 
	set order_by_clause "order by (ci.effective_date)" 
	set counter_reset_expression {$effective_month}
    }
    "Amount" { 
	set order_by_clause "order by ci.amount" 
    }
    "Paid" { 
	set order_by_clause "order by ci.paid_amount" 
    }
    "Status" { 
	set order_by_clause "order by cost_status_id" 
	set counter_reset_expression {$cost_status_id}
    }
    "Type" { 
	set order_by_clause "order by cost_type" 
	set counter_reset_expression {$cost_type_id}
    }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

# -----------------------------------------------------------------
# Define extra SQL for payments
# -----------------------------------------------------------------

set payment_amount ""
set payment_currency ""

set extra_from ""
set extra_where ""


# -----------------------------------------------------------------
# Main SQL
# -----------------------------------------------------------------

set sql "
select
        i.*,
	(to_date(to_char(i.invoice_date,:date_format),:date_format) + i.payment_days) as due_date_calculated,
	o.object_type,
	(ci.amount * (1 + coalesce(ci.vat,0)/100 + coalesce(ci.tax,0)/100)) as invoice_amount,
	ci.currency as invoice_currency,
	ci.paid_amount as payment_amount,
	to_char(ci.paid_amount,:cur_format) as payment_amount_formatted,
	ci.paid_currency as payment_currency,
	pr.project_nr,
	to_char(ci.effective_date, 'YYYY-MM') as effective_month,
	to_char(ci.amount * (1 + coalesce(ci.vat,0)/100 + coalesce(ci.tax,0)/100), :cur_format) as invoice_amount_formatted,
    	im_email_from_user_id(i.company_contact_id) as company_contact_email,
      	im_name_from_user_id(i.company_contact_id) as company_contact_name,
	im_cost_center_code_from_id(ci.cost_center_id) as cost_center_code,
	im_cost_center_name_from_id(ci.cost_center_id) as cost_center_name,
        c.company_name as customer_name,
        c.company_path as company_short_name,
	p.company_name as provider_name,
	p.company_path as provider_short_name,
	to_date(:today, :date_format) - (to_date(to_char(i.invoice_date, :date_format),:date_format) + i.payment_days) as overdue
        $extra_select_sql
from
        im_invoices_active i,
        im_costs ci
	LEFT OUTER JOIN im_projects pr on (ci.project_id = pr.project_id)
	left outer join (	select distinct
			cc.cost_center_id,
			ct.cost_type_id
		from	im_cost_centers cc,
			im_cost_types ct,
			acs_permissions p,
			party_approved_member_map m,
			acs_object_context_index c, 
			acs_privilege_descendant_map h
		where
			p.object_id = c.ancestor_id
			and h.descendant = ct.read_privilege
			and c.object_id = cc.cost_center_id
			and m.member_id = :user_id
			and p.privilege = h.privilege
			and p.grantee_id = m.party_id
	) readable_ccs on (ci.cost_center_id = readable_ccs.cost_center_id
	and ci.cost_type_id = readable_ccs.cost_type_id),
	acs_objects o,
        im_companies c,
        im_companies p
	$extra_from
where
	i.invoice_id = o.object_id
	and i.invoice_id = ci.cost_id
 	and i.customer_id=c.company_id
        and i.provider_id=p.company_id
	$company_where
        $where_clause
	$extra_where
$order_by_clause
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites
#

if {[string equal $letter "ALL"]} {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection $sql
} else {
    # We can't get around counting in advance if we want to be able to
    # sort inside the table on the page for only those users in the
    # query results
    set total_in_limited [db_string total_in_limited "
        select count(*)
        from ($sql) s
    "]
    set selection [im_select_row_range $sql $start_idx $end_idx]
}



# ---------------------------------------------------------------
# 6a. Format the Filter: Get the admin menu
# ---------------------------------------------------------------

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
    set new_document_menu "<ul>"
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	ns_log Notice "im_sub_navbar: menu_name='$name'"
	regsub -all " " $name "_" name_key
	set name_loc [lang::message::lookup "" $package_name.$name_key $name]
	append new_document_menu "<li><a href=\"$url\">$name_loc</a></li>\n"
	incr ctr
    }
    append new_document_menu "</ul>"
    if {0 == $ctr} { set new_document_menu "" }
}

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options

set form_id "invoice_filter"
set object_type "im_invoice"
set action_url "/intranet-invoices/list"
set form_mode "edit"
set company_options [im_company_options -include_empty_p 1 -include_empty_name "#intranet-core.All#" -type "CustOrIntl" ]

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many include_subinvoices_p}\
    -form {
	{cost_status_id:text(im_category_tree),optional {label \#intranet-invoices.Document_Status\#} {value $cost_status_id} {custom {category_type "Intranet Cost Status" translate_p 1 include_empty_p 1} } }
	{cost_type_id:text(im_category_tree),optional {label \#intranet-invoices.Document_Type\#} {value $cost_type_id} {custom {category_type "Intranet Cost Type" translate_p 1 include_empty_p 1} } }
	{company_id:text(select),optional {label \#intranet-invoices.Company\#} {options $company_options} {value $company_id}}
	{start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >}}}
	{end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('end_date', 'y-m-d');" >}}}
	{view_name:text(select) {label \#intranet-core.View_Name\#} {value "$view_name"} {options {{"Invoice List" invoice_list} {"Customers" invoice_customer_list} {"Providers" invoice_provider_list}}}}
}

# List to store the view_type_options
set view_type_options [list [list Tabelle ""]]

# Run callback to extend the filter and/or add items to the view_type_options
callback im_projects_index_filter -form_id $form_id
ad_form -extend -name $form_id -form {
    {view_type:text(select),optional {label "#intranet-openoffice.View_type#"} {options $view_type_options}}
}

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="invoice_filter" style="tiny-plain-po"></formtemplate>}]
set filter_html $__adp_output

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""

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
    regsub -all " " $col "_" col_key
    regsub -all "#" $col_key "hash_simbol" col_key
    set col_loc [lang::message::lookup ""  intranet-invoices.$col_key $col]

    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col_loc</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_loc</a></td>\n"
    }
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx

# Create a ns_set with all local variables in order
# to pass it to the SQL query
set form_vars [ns_set create]
foreach varname [info locals] {

    # Don't consider variables that start with a "_", that
    # contain a ":" or that are array variables:
    if {"_" == [string range $varname 0 0]} { continue }
    if {[regexp {:} $varname]} { continue }
    if {[array exists $varname]} { continue }

    # Get the value of the variable and add to the form_vars set
    set value [expr "\$$varname"]
    ns_set put $form_vars $varname $value
}

callback im_invoices_index_before_render -view_name $view_name \
    -view_type $view_type -sql $selection -table_header $page_title -variable_set $form_vars

db_foreach invoices_info_query $selection {

    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Translate the categories
    set cost_type [im_category_from_id $cost_type_id]
    set cost_status [im_category_from_id $cost_status_id]
    set invoice_status [im_category_from_id $invoice_status_id]

    # Don't show paid invices over due in red:
    if {$invoice_status_id == [im_cost_status_paid] || \
	$invoice_status_id == [im_cost_status_filed]} {
	set overdue 0
    }

    # paid_amount="" => paid_amount=0
    if {"" == $paid_amount} { set paid_amount 0}
    if {"" == $amount} { set amount 0}

    if {$payment_amount eq ""} { set payment_currency ""}
    # ---- Deal with non-writable Invoices ----

    # Calculate the statu-select drop-down for this invoice
    set status_select [im_cost_status_select "cost_status.$invoice_id" $invoice_status_id]

    set write_p [im_cost_center_write_p $cost_center_id $cost_type_id $user_id]
    if {!$write_p} {
	set status_select ""
	# Bad Trick: " " let the Del-checkbox disappear...
        if {"" == $payment_amount} { set payment_amount " " }
    }

    # ---- Display the main line ----

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
	eval $cmd
	append table_body_html "</td>\n"
    }
    append table_body_html "</tr>\n"

    # ----

    incr ctr
    if { $how_many > 0 && $ctr > $how_many } {
	break
    }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        [_ intranet-invoices.lt_There_are_currently_n]
        </b></ul></td></tr>"
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 0]
    set next_page_url "$local_url?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
    set next_page "<a href=$next_page_url>[_ intranet-invoices.Next_Page]</a>"
} else {
    set next_page_url ""
    set next_page ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "$local_url?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
    set previous_page "<a href=$previous_page_url>[_ intranet-invoices.Previous_Page]</a>"
} else {
    set previous_page_url ""
    set previous_page ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

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
    <input type=submit name=submit_save value='[_ intranet-invoices.Save]'>
  </td>
  <td align=center>
    <input type=submit name=submit_del value='[_ intranet-invoices.Del]'>
  </td>
</tr>"

set sub_navbar [im_costs_navbar "no_alpha" "/intranet-invoices/list" $next_page_url $previous_page_url [list invoice_status_id cost_type_id company_id start_idx order_by how_many view_name start_date end_date] $parent_menu_label ]

set left_navbar_html "
            <div class='filter-block'>
                <div class='filter-title'>
                #intranet-invoices.Filter_Documents#
                </div>
                $filter_html
            </div>
            <hr/>

            <div class='filter-block'>
                <div class='filter-title'>
                #intranet-invoices.lt_New_Company_Documents#
                </div>
                $new_document_menu
            </div>
            <hr/>
"

