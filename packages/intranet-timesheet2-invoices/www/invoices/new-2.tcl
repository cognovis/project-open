# /packages/intranet-timesheet2-invoices/www/new-2.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Receives a list of projects and displays all Tasks of these projects,
    ordered by project, allowing the user to modify the "billable units".
    Provides a button to advance to "new-3.tcl".

    @author frank.bergmann@poject-open.com
} {
    { select_project:multiple }
    invoice_currency
    target_cost_type_id:integer
    { cost_center_id:integer 0}
    { start_date "" }
    { end_date "" }
    { return_url ""}
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set current_url [im_url_with_query]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"
set page_title "New Timesheet Invoice"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-timesheet2-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-timesheet2-invoices.lt_You_dont_have_suffici]"    
}


# Do we need the cost_center_id for creating a new invoice?
# This is necessary if the invoice_nr depends on the cost_center_id (profit center).
set cost_center_required_p [parameter::get_from_package_key -package_key "intranet-invoices" -parameter "NewInvoiceRequiresCostCenterP" -default 0]
if {$cost_center_required_p && ($cost_center_id == "" || $cost_center_id == 0)} {
    ad_returnredirect [export_vars -base "/intranet-invoices/new-cost-center-select" {
	{pass_through_variables {cost_type_id customer_id provider_id project_id invoice_currency create_invoice_from_template select_project source_cost_type_id target_cost_type_id start_date end_date}}
	select_project
	cost_type_id 
	source_cost_type_id 
	target_cost_type_id 
	customer_id 
	provider_id 
	project_id 
	invoice_currency 
	cost_center_id
	start_date
	end_date
	create_invoice_from_template 
	{return_url $current_url}
    }]
}

set target_cost_type [im_category_from_id $target_cost_type_id]

set allowed_cost_type [im_cost_type_write_permissions $current_user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}

if {[info exists select_project]} {
    set project_id $select_project
    if {[llength $select_project] > 1} {
	set project_id [lindex $select_project 0]
    }
    set project_name [db_string project_name "select project_name from im_projects where project_id = :project_id" -default ""]
    if {"" != $project_name} {
	append page_title " for Project '$project_name'"
    }
}


# ---------------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------------

# Choose the right subnavigation bar
#
if {[llength $select_project] != 1} {
    set sub_navbar [im_costs_navbar "none" "/intranet/invoicing/index" "" "" [list]]
} else {
    # Setup the subnavbar
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set menu_label "project_finance"
    set sub_navbar [im_sub_navbar \
			-components \
			-base_url "/intranet/projects/view?project_id=$project_id" \
			$parent_menu_id \
			$bind_vars "" "pagedesriptionbar" $menu_label]
}

# ---------------------------------------------------------------
# Check start- and end_date
# ---------------------------------------------------------------

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set days_in_past 30
db_1row todays_date "
    select
        to_char(sysdate::date - :days_in_past::integer, 'YYYY') as start_year,
        to_char(sysdate::date - :days_in_past::integer, 'MM') as start_month,
        to_char(sysdate::date - :days_in_past::integer, 'DD') as start_day
    from dual
"
if {"" == $start_date} {
    set start_date "$start_year-$start_month-01"
}

set days_in_future "45 days"
db_1row end_date "
    select
        to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_future::interval, 'YYYY') as end_year,
        to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_future::interval, 'MM') as end_month,
        to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_future::interval, 'DD') as end_day
    from dual
"
if {"" == $end_date} {
    set end_date "$end_year-$end_month-01"
}

# ---------------------------------------------------------------
# 3. Check the consistency of the select project and get client_id
# ---------------------------------------------------------------

# check that all projects are from the same client
set clients [db_list clients "
	select	distinct company_id
	from	im_projects
	where	project_id in ([join $select_project ","])
"]

if {[llength $clients] > 1} {
    ad_return_complaint "[_ intranet-timesheet2-invoices.lt_You_have_selected_mul]" "
        <li>[_ intranet-timesheet2-invoices.lt_You_have_selected_mul_1]<BR>
            [_ intranet-timesheet2-invoices.lt_Please_backup_and_res]"
    return
}

# now we know that all projects are from a single company:
set company_id [lindex $clients 0]


# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

set form_id "filter"
set object_type "im_project"
set action_url [export_vars -base [ns_conn url] {}]
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {select_project target_cost_type_id invoice_currency cost_center_id } \
    -form {
        {start_date:text(text),optional {label "Start Date"}}
        {end_date:text(text),optional {label "End Date"}}
    }

template::element::set_value $form_id start_date $start_date
template::element::set_value $form_id end_date $end_date


# ---------------------------------------------------------------
# Get the list of tasks
# ---------------------------------------------------------------

set task_table_rows [im_timesheet_invoicing_project_hierarchy \
			 -select_project $select_project \
			 -start_date $start_date \
			 -end_date $end_date \
			 -invoice_hour_type "" \
]

