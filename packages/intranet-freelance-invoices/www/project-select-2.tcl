# /packages/intranet-freelance-invoices/www/project-select-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Select a project from a customer for generating
    a purchase order.

    @author frank.bergmann@project-open.com
} {
    return_url
    company_id:integer
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "project_personal_list" }
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-invoices.Select_Project]"
set context_bar [im_context_bar $page_title]

# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
}
set end_idx [expr $start_idx + $how_many - 1]

# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# Columns to show:

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
# Generate SQL Query

set perm_sql "
	(select
	        p.*
	from
	        im_projects p,
		acs_rels r
	where
		r.object_id_one = p.project_id
		and r.object_id_two = :user_id
		and p.parent_id is null
	)"

set personal_project_query "
	SELECT
		p.*,
	        c.company_name,
	        im_name_from_user_id(project_lead_id) as lead_name,
	        im_category_from_id(p.project_type_id) as project_type,
	        im_category_from_id(p.project_status_id) as project_status,
	        to_char(end_date, 'YYYY-MM-DD') as end_date,
	        to_char(end_date, 'HH24:MI') as end_date_time
	FROM
		$perm_sql p,
		im_companies c
	WHERE
		p.company_id = c.company_id
    "

    
# ---------------------------------------------------------------
# Format the List Table Header

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html "<tr>\n"
foreach col $column_headers {
    regsub -all " " $col "_" col_txt
    set col_txt [_ intranet-core.$col_txt]
    append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
}

append table_header_html "\t<td class=rowtitle>Select</td>\n"
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# Format the Result Data

set url "index?"
set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
db_foreach personal_project_query $personal_project_query {

    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }
    
    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	eval "$cmd"
	append row_html "</td>\n"
    }
    
    set select_url "$return_url&project_id=$project_id"
    append row_html "<td><a href=\"$select_url\">Select</a></td>\n"

    append row_html "</tr>\n"
    append table_body_html $row_html
    
    incr ctr
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
	[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
        </b></ul></td></tr>"
}
