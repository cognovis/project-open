# /packages/intranet-portfolio-management/tcl/intranet-portfolio-management-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------


ad_proc -public im_program_portfolio_sweeper {
} {
    Periodic process to update the budget, percent_completed, start_date
    and end_date of programs.
} {
    set programs_sql "
	select	project_id
	from	im_projects
	where	parent_id is null and
		project_type_id = [im_project_type_program]
    "
    set programs [db_list programs $programs_sql]

    set admin_user_id [db_string cur_user "select min(user_id) from users where user_id > 0"]
    foreach program_id $programs {
	im_program_portfolio_list_component \
		-program_id $program_id \
		-current_user_id $admin_user_id
    }
}


ad_proc -public im_program_portfolio_list_component {
    -program_id:required
    {-show_empty_project_list_p 1}
    {-view_name "program_portfolio_list" }
    {-order_by_clause ""}
    {-project_type_id 0}
    {-project_status_id 0}
    {-current_user_id 0}
} {
    Returns a HTML table with the list of projects of the
    current user. Don't do any fancy with sorting and
    pagination, because a single user won't be a member of
    many active projects.

    @param show_empty_project_list_p Should we show an empty project list?
           Setting this parameter to 0 the component will just disappear
           if there are no projects.
} {
    # The owner of the system...
    set admin_user_id [db_string cur_user "select min(user_id) from users where user_id > 0"]

    # Is this a "Program" Project?
    # The portfolio view only makes sense in programs...
    set program_info_sql "
	select	project_type_id as program_type_id,
		round(percent_completed::numeric,1) as program_percent_completed,
		round(project_budget::numeric,1) as program_budget,
		start_date as start_date_program,
		end_date as end_date_program
	from	im_projects
	where	project_id = :program_id
    "
    db_1row program_inf $program_info_sql
    if {![im_category_is_a $program_type_id [im_project_type_program]]} { return "" }

    if {"" == $current_user_id || 0 == $current_user_id} { set current_user_id [ad_get_user_id] }
    set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

    set date_format "YYYY-MM-DD"

    set return_url [im_url_with_query]

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-portfolio-management" -parameter "ProgramPortfolioListSortClause" -default "project_nr DESC"]
    }

    # ---------------------------------------------------------------
    # Columns to show:
    set view_id [db_string get_view_id "select view_id from im_views where view_name = :view_name"]
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]

    set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for,
	        extra_where,
	        extra_select,
	        extra_from
	from	im_view_columns
	where	view_id = :view_id
		and group_id is null
	order by sort_order
    "
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    set extra_select [join $extra_selects ",\n\t"]
    if { ![empty_string_p $extra_select] } {
	set extra_select ",\n\t$extra_select"
    }

    set extra_from [join $extra_froms ",\n\t"]
    if { ![empty_string_p $extra_from] } {
	set extra_from ",\n\t$extra_from"
    }

    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_where] } {
	set extra_where "and\n\t$extra_where"
    }

    # Project Status restriction
    set project_status_restriction ""
    if {0 != $project_status_id} {
	set project_status_restriction "and p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
    }

    # Project Type restriction
    set project_type_restriction ""
    if {0 != $project_type_id} {
	set project_type_restriction "and p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
    }

    set perm_sql "
	(select
	        p.*
	from
	        im_projects p,
		acs_rels r
	where
		r.object_id_one = p.project_id and
		r.object_id_two = :current_user_id and
		p.parent_id is null and
		p.program_id = :program_id and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		p.project_status_id not in ([im_project_status_deleted], [im_project_status_closed])
		$project_status_restriction
		$project_type_restriction
	)
    "

    if {$current_user_id == $admin_user_id || [im_permission $current_user_id "view_projects_all"]} {
	set perm_sql "
	(select	p.*
	from	im_projects p
	where	p.parent_id is null and
		p.program_id = :program_id and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
                p.project_status_id not in ([im_project_status_deleted], [im_project_status_closed])
                $project_status_restriction
                $project_type_restriction
	)"
    }

    set program_query "
	SELECT
		p.*,
		to_char(p.start_date, :date_format) as start_date_formatted,
		to_char(p.end_date, :date_format) as end_date_formatted,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_ansi,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_ansi,
		coalesce(cost_bills_cache,0.0) + 
			coalesce(cost_expense_logged_cache,0.0) + 
			coalesce(cost_timesheet_logged_cache,0.0) as real_costs,
		coalesce(cost_purchase_orders_cache,0.0) + 
			coalesce(cost_expense_planned_cache,0.0) + 
			coalesce(cost_timesheet_planned_cache,0.0) as planned_costs,
	        c.company_name,
		round(p.percent_completed::numeric,1) as percent_completed_rounded,
	        im_name_from_user_id(project_lead_id) as lead_name,
	        im_category_from_id(p.project_type_id) as project_type,
	        im_category_from_id(p.project_status_id) as project_status,
	        to_char(end_date, 'HH24:MI') as end_date_time
                $extra_select
	FROM
		$perm_sql p,
		im_companies c
                $extra_from
	WHERE
		p.company_id = c.company_id
		$project_status_restriction
		$project_type_restriction
                $extra_where
	order by $order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {

	set admin_html ""
	if {$admin_p} {
	    set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	    set admin_html "<a href='$url'>[im_gif wrench ""]</a>"
	}

	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	append table_header_html "  <td class=rowtitle>$col_txt $admin_html</td>\n"
    }
    append table_header_html "</tr>\n"


    # ---------------------------------------------------------------
    # Format the Result Data

    set url "index?"
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0

    # Total amounts of budget and quotes of the included projects
    set budget_total 0.0
    set quotes_total 0.0
    set plain_total 0.0

    # "Done" (total x percent_completed) amounts of budget and 
    # quote of the included projects
    set budget_done 0.0
    set quotes_done 0.0
    set plain_done 0.0

    set var_list {
	planned_costs
	real_costs
	cost_bills_cache
	cost_cache_dirty
	cost_delivery_notes_cache
	cost_expense_logged_cache
	cost_expense_planned_cache
	cost_invoices_cache
	cost_purchase_orders_cache
	cost_quotes_cache
	cost_timesheet_logged_cache
	cost_timesheet_planned_cache
	reported_days_cache
	reported_hours_cache
    }
    
    foreach var $var_list { set "${var}_total" 0 }

    set start_date_min "2099-12-31"
    set end_date_max "2000-01-01"
    db_foreach program_query $program_query {

        if {"" == $percent_completed} { set percent_completed 0.0 }

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
	append row_html "</tr>\n"
	append table_body_html $row_html

	# Avoid error due to NULL values
	if {"" == $cost_quotes_cache} { set cost_quotes_cache 0 }
	if {"" == $project_budget} { set project_budget 0 }

	set quotes_total [expr $quotes_total + $cost_quotes_cache]
	set budget_total [expr $budget_total + $project_budget]
	set plain_total [expr $plain_total + 1.0]

	set quotes_done [expr $quotes_done + $cost_quotes_cache * $percent_completed / 100.0]
	set budget_done [expr $budget_done + $project_budget * $percent_completed / 100.0]
	set plain_done [expr $plain_done + 1.0 * $percent_completed / 100.0]

	foreach var $var_list {

	    # Sum up the column's values into totals
	    set val [set $var]
	    if {"" == $val} { set val 0 }
	    if {[catch { 
		set cmd "set ${var}_total \[expr \$${var}_total + $val\]"
		eval $cmd
	    } err_msg]} {
		ad_return_complaint 1 "<pre>$err_msg</pre>"
	    }
	}

	if {$start_date_ansi < $start_date_min} { set start_date_min $start_date_ansi }
	if {$end_date_ansi > $end_date_max} { set end_date_max $end_date_ansi }

	incr ctr
    }


    # Update the program's %done and budget values
    # Allow to use either quotes or budget for calculation
    set completed 0.0
    if {0.0 != $plain_total} {
	set completed [expr round(1000.0 * $plain_done / $plain_total) / 10.0]
    }
    # Quotes override aritmetic median
    if {0.0 != $quotes_total} {
	# Santa: Projects usually don't have a budget...
	# set completed [expr round(1000.0 * $quotes_done / $quotes_total) / 10.0]
    }
    # budget overrides quotes
    if {0.0 != $budget_total} {
	set completed [expr round(1000.0 * $budget_done / $budget_total) / 10.0]
    }

    # Total summary line:
    # Copy the *_total values into the values without _total
    if {$ctr > 0} {
	foreach var $var_list { set $var [set ${var}_total] }
	set project_name ""
	set project_nr ""
	set on_track_status_id ""
	set percent_completed_rounded $completed
	set start_date $start_date_min
	set end_date $end_date_max
	
	# Display the same row with summary values
	set row_html "<tr>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td class=rowtitle>"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
	append row_html "</tr>\n"
	append table_body_html $row_html
    }


    # Update the program with information from the included projects
    set update_html ""
    if {$program_percent_completed != $completed || $program_budget != $budget_total || $start_date_program != $start_date_min || $end_date_program != $end_date_max} {
	db_dml update_program_advance "
		update im_projects set
			percent_completed = :completed,
			project_budget = :budget_total,
			start_date = :start_date_min,
			end_date = :end_date_max
		where
			project_id = :program_id
	"
	im_audit -object_id $project_id
	set update_html "<font color=red>[lang::message::lookup "" intranet-portfolio-management.Updated_the_program_budget_and_advance "Updated the program's budget=%budget_total% and advance=%completed%"]</font>"
    }

    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {

	# Let the component disappear if there are no projects...
	if {!$show_empty_project_list_p} { return "" }

	set table_body_html "
	    <tr><td colspan=\"$colspan\"><ul><li><b> 
	    [lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
	    </b></ul></td></tr>
	"
    }
    
    set add_project_url [export_vars -base "/intranet-portfolio-management/add-project-to-portfolio" {return_url {program_id $program_id}}]
    return "
	<table class=\"table_component\" width=\"100%\">
	<thead>$table_header_html</thead>
	<tbody>$table_body_html</tbody>
	</table>
	$update_html
	<ul>
	<li><a href=\"$add_project_url\">[lang::message::lookup "" intranet-portfolio-management.Add_a_project_to_the_portfolio "Add a project to the portfolio"]</a></li>
	</ul>
    "
}
