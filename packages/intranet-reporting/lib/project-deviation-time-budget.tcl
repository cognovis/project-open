# /packages/intranet-reporting/lib/project-deviation-time-budget
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

# author: Klaus Hofeditz klaus.hofeditz@project-open.com 
# author: Frank Bergmann frank.bergmann@project-open.com  

# History: 
# This report had been initially created for a highly customized ]po[ installation
# and was based on a similar, already existing report. Therefore it does 
# not really serve as a model in terms of structure etc.   
# It has been roughly adjusted so that it works for a ]po[ standard installation 
# and has been moved to the intranet-reporting package. Additional steps 
# might be necessary before making it available in the product
# kh 

# ------------------------------------------------------------
# Request for component 

if { ![info exists opened_projects] } { set opened_projects "" }
if { ![info exists user_id_from_search] } { set user_id_from_search "" }
if { ![info exists project_status_id_from_search] } { set project_status_id_from_search "" }
if { ![info exists start_date] } { set start_date "" }
if { ![info exists end_date] } { set end_date "" }
if { ![info exists customer_id] } { set customer_id "" }

set project_id_from_filter $project_id

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.

set menu_label "project-deviation-time-budget"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

# Permissions
set full_view_p 0 
if {
    [im_profile::member_p -profile_id [im_accounting_group_id] -user_id $current_user_id] || \
    [im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "Senior Managers"] -user_id $current_user_id] || \
    [acs_user::site_wide_admin_p] \
} {
    set full_view_p 1
}


if { ![string equal "t" $read_p] && 0 == $full_view_p } {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# Ugly but effective: Remove list markup to convert param into a list...
regsub -all {\{} $opened_projects "" opened_projects
regsub -all {\}} $opened_projects "" opened_projects


# Check security. opened_projects should only contain integers.
if {[regexp {[^0-9\ ]} $opened_projects match]} {
    catch {im_security_alert \
	       -location "Timesheet Finance Report" \
	       -value $opened_projects \
	       -message "Received non-integer value for opened_projects" 
    } err
    ad_return_complaint 1 "Invalid argument:<br>opened_projects=$opened_projects"
    ad_script_abort
}

if { "" == $user_id_from_search  } { set user_id_from_search 0 }

# ------------------------------------------------------------
# Constants & Options

# Set AJAX update company/project
im_reporting_form_update_ajax \
	"intranet-reporting-project-deviation-time-budget" \
	"im_company" \
	"im_project" \
	"customer_id" \
	"project_id" \
	"company_id" \
	"project_id" \
    	"{exclude_status_id -1} {exclude_subprojects_p 1} {include_empty 1} {include_empty_name {[lang::message::lookup "" intranet-reporting.All_Projects_From_Customers "All projects from customer"]} }"

set page_title "[lang::message::lookup "" intranet-reporting.Title_Budget_Report "Project Deviation Time & Budget"] (BETA)"
set context_bar [im_context_bar $page_title]
set context ""
set rounding_precision 2
set locale [lang::user::locale]
set format_string "%0.2f"

set first_request_p 0
set internal_company_id [im_company_internal]
set cc_company_id [im_cost_center_company]

if { 0 == $project_status_id_from_search } {
    set project_status_id_from_search ""
}

# ----
# Get employee(s)
# ----
set where_employees "1=1"
if { 0 != $user_id_from_search  } { append where "\n and employee_id = $user_id_from_search" } 
set sql "select employee_id from im_employees where $where_employees"
set employee_id [db_list emp_list $sql] 

if {[llength $opened_projects] == 0} { set opened_projects [list 0] }

# Check that Start & End-Date have correct format
if { [catch { set start_date_ansi [clock format [clock scan $start_date] -format %Y-%m-%d] } ""] } {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if { [catch { set end_date_ansi [clock format [clock scan $end_date] -format %Y-%m-%d] } ""] } {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set days_in_past 7

db_1row todays_date "
	select
		to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
		to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
		to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
	from dual
"

if { "" == $start_date } {
    set start_date "2000-01-01"
    if { "component_html" != $output_format } {
	set first_request_p 1
    }
}

db_1row end_date "
	select
		to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
		to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
		to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
	from dual
"

if {"" == $end_date} {
    set end_date "2030-12-31"
}


set user_options [im_profile::user_options -profile_ids [im_profile_employees]]
set user_options [linsert $user_options 0 [list [lang::message::lookup "" intranet-core.all "All"] ""]]

set customer_url "/intranet/companies/view?customer_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/project-deviation-time-budget" {start_date end_date} ]
set current_url [im_url_with_query]


# ------------------------------------------------------------
# Set criterias 
# ------------------------------------------------------------

set criteria [list]

# First request, give user the chance to set filter
if { $first_request_p && "component_html" != $output_format} {
    lappend criteria "p.project_id = -1"
}

# Customers
if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}

# Users 
if { "" != $user_id_from_search && 0 != $user_id_from_search } {
    lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search)"
}

# Projects
if { "" != $project_id_from_filter && 0 != $project_id_from_filter } {
    lappend criteria "p.project_id = :project_id_from_filter"
}

# Project Start/End date 
if {"" != $start_date} {
    lappend criteria "p.end_date >= :start_date::timestamptz"
}
if {"" != $end_date} {
    lappend criteria "p.start_date < :end_date::timestamptz"
}

# Project Status
if { "" != $project_status_id_from_search } {
    lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id_from_search] ,]) "
}

# Limited vs. Full View (Senior Manager & Accounting)
if { !$full_view_p } {
    lappend criteria "p.project_lead_id = :current_user_id"
}

# Build where-clause
set where_clause [join $criteria "\n\tand "]
if {"" != $where_clause} { set where_clause "and $where_clause" }

# ------------------------------------------------------------
# Calculate the transitive superprojs for projects, that is
# sub_project_id => {sub_project_id, parent_1_id, parent_2_id, ...}
# ------------------------------------------------------------

set project_superprojs_sql "
	select
		p.project_id as child_id,
		p.parent_id
	from
		im_projects p

"

array set project_parent {}
array set project_has_children_p {}
array set project_direct_children {}

db_foreach project_superprojs $project_superprojs_sql {
    # Setup the project->parent relation
    set project_parent($child_id) $parent_id

    # Determine if a project has children
    # Consider only projects, since we do not show tasks 
    set project_has_children_p($parent_id) 1  	

    # Setup the list of direct children of a project
    if {"" != $parent_id} { 
	set l [list]
	if {[info exists project_direct_children($parent_id)] } { set l $project_direct_children($parent_id) }
	lappend l $child_id
	set project_direct_children($parent_id) $l
    }
}

# ------------------------------------------------------------
# Calculate the transitive closures of super-projects
# Start the iteration with the project->parent relationship. 
# In a second step we'll check if the parent project has further 
# parents and add these ones respectively.
# We use a list of "ToDo items" incomplete_projects.
# ------------------------------------------------------------

array set project_parents [array get project_parent]
set incomplete_projects [array names project_parents]

set cnt 0
while {[llength $incomplete_projects] > 0} {
    set new_incomplete_projects [list]
    foreach incomplete_project $incomplete_projects {

	set parents $project_parents($incomplete_project)
	set topmost_parent [lindex $parents 0]
	if {[info exists project_parent($topmost_parent)]} { 
	    
	    set parents_parent $project_parent($topmost_parent)
	    if {"" != $parents_parent} {
		
		# The parent of our "incomplete_project" has a parent.
		# Add the parent's parent to the front of the list
		# and iterate (all the item to new_incomplete_projects)
		
		set parents [linsert $parents 0 $parents_parent]
		set project_parents($incomplete_project) $parents
		
		lappend new_incomplete_projects $incomplete_project
		
	    }
	}
    }
    set incomplete_projects $new_incomplete_projects
    incr cnt
    if {$cnt > 100} { ad_return_complaint 1 "<b>Timesheet Finance Report</b>:<br>Infinite loop: $cnt" }
}

# ------------------------------------------------------------
# Calculate the transitive closures of sub-projects
# That's easy, because we have already the transitive closure of
# super-projects, which we only have to reorder.
# ------------------------------------------------------------

array set project_children {}
foreach project [array names project_parents] {
    set parents $project_parents($project)
    foreach parent $parents {
	set all_children [list]
	if {[info exists project_children($parent)]} { set all_children $project_children($parent) }
	lappend all_children $project
	set project_children($parent) $all_children
    }
}

# ------------------------------------------------------------
# Calculate the sum of hours per project and user
# and store the result in a hash array.
# ------------------------------------------------------------

set hours_criteria [list]
if {[llength $employee_id] > 0} {
    lappend hours_criteria "h.user_id in ([join $employee_id ","])"
}
set hours_where [join $hours_criteria "\n\tand "]
if {"" != $hours_where} { set hours_where "and $hours_where" }

set hours_sql "
	SELECT 	h.project_id as hours_project_id,
		h.user_id,
		SUM(hours) AS logged_hours,
		im_name_from_user_id(h.user_id) AS name
	FROM	im_hours h
	WHERE	user_id in (
			select	member_id
			from	group_distinct_member_map
			where	group_id = [im_employee_group_id]
		)
		and h.day >= to_date(:start_date::text, 'YYYY-MM-DD')
		and h.day < to_date(:end_date::text, 'YYYY-MM-DD')
		$hours_where
	GROUP BY 
		h.project_id, h.user_id
	HAVING SUM(hours) > 0
"

array set users {}
array set project_hours {}

db_foreach hours $hours_sql {
    set users($user_id) $name

    if { ![info exists projects($hours_project_id,$user_id)] } {
	set projects($hours_project_id,$user_id) 0
    }
    set projects($hours_project_id,$user_id) [expr $projects($hours_project_id,$user_id) + $logged_hours]

    foreach parent_id $project_parents($hours_project_id) {
	if { ![info exists projects($parent_id,$user_id)] } {
	    set projects($parent_id,$user_id) 0
	}
	set projects($parent_id,$user_id) [expr $projects($parent_id,$user_id) + $logged_hours]
    }

}

# ------------------------------------------------------------
# Create the main list
# ------------------------------------------------------------

# ###
# Set lables
# ###

set label_client [lang::message::lookup "" intranet-core.Client "Client"]
set label_project_name [lang::message::lookup "" intranet-core.Project_Name "Project Name"]
set label_project_manager [lang::message::lookup "" intranet-core.Project_Manager "Project Status"]
set label_end_date [lang::message::lookup "" intranet-core.End_Date "End date"]
set label_percent_completed [lang::message::lookup "" intranet-timesheet2-tasks.Percentage_completed "Percentage completed"]
set label_project_budget_hours [lang::message::lookup "" intranet-core.Project_Budget_Hours "Project Budget (hours)"]
set label_hours_logged [lang::message::lookup "" intranet-reporting.Hours_logged "Hours logged"]
set label_deviation_target [lang::message::lookup "" intranet-reporting.Deviation_Target "Deviation Target"]
set label_projection_hours [lang::message::lookup "" intranet-reporting.Projection_Hours "Projection Hours"]
set label_delta_projection_hours_budget [lang::message::lookup "" intranet-reporting.Ddelta_Projection_Hours_Budget "Delta Projection (hours) & Budget"]
set label_project_budget [lang::message::lookup "" intranet-core.Project_Budget "Project Budget"]
set label_costs_matrix [lang::message::lookup "" intranet-reporting.Costs_Matrix "Costs"]
set label_delta_budget_costs [lang::message::lookup "" intranet-reporting.Delta_Budget_Costs "Delta Budget/Costs"]
set label_projection_costs [lang::message::lookup "" intranet-reporting.Projection_Costs "Projection Costs"]
set label_delta_budget_projection [lang::message::lookup "" intranet-reporting.Delta_Budget_Projection "Delta Budget/Projection"]


# ###
# Define list elements 
# ###

set elements [list]

# Company 
lappend elements company_id
lappend elements { label "" }

lappend elements company_name
lappend elements {
    label $label_client
    display_template {
                <a href="/intranet/companies/view?company_id=@project_list.company_id@">@project_list.company_name@</a>
                </nobr>
    }
}


# Project 
lappend elements project_id
lappend elements {
    label ""
}

lappend elements project_type_id
lappend elements { label "Project Type ID"}


lappend elements project_name 
lappend elements {
    label $label_project_name
    display_template { 
		<nobr>@project_list.level_spacer;noquote@ 
		@project_list.open_gif;noquote@
		<a href="/intranet/projects/view?project_id=@project_list.child_id@">@project_list.project_name@</a>
		</nobr> 
    }
}

lappend elements project_manager
lappend elements {
    label $label_project_manager
    display_template {
	<nobr><a href="/intranet/users/view?user_id_id=@project_lead_id@">@project_list.project_manager@</a></nobr>
    }
}


# end_date 
lappend elements end_date
lappend elements {
    label $label_end_date
}

# percent_completed 
lappend elements percent_completed
lappend elements {
    label $label_percent_completed
}

# project_budget_hours 
lappend elements project_budget_hours
lappend elements {
    label $label_project_budget_hours
}

# hours_logged
lappend elements hours_logged
lappend elements {
    label $label_hours_logged
}


# deviation_target 
lappend elements deviation_target
lappend elements {
    label $label_deviation_target
}

# projection_hours 
lappend elements projection_hours
lappend elements {
    label $label_projection_hours
}

# delta_projection_hours_budget 
lappend elements delta_projection_hours_budget
lappend elements {
    label $label_delta_projection_hours_budget
}

# project_budget 
lappend elements project_budget
lappend elements {
    label $label_project_budget
}



# costs_matrix 
lappend elements costs_matrix
lappend elements {
    label $label_costs_matrix
}

# delta_budget_costs 
lappend elements delta_budget_costs
lappend elements {
    label $label_delta_budget_costs
}

# projection_costs 
lappend elements delta_budget_costs
lappend elements {
    label $label_delta_budget_costs
}

# delta_budget_projection 
lappend elements delta_budget_projection
lappend elements {
    label $label_delta_budget_projection
}


# ------------------------------------------------------------

set company_name_saved ""

set provider_bill_select "
        (select
                trunc(sum(amount),2)
        from
                im_costs
        where
                project_id in (
                        select
                                p_child.project_id
                        from
                                im_projects p_parent,
                                im_projects p_child
                        where
                                p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                and p_parent.project_id = child.project_id
                        )
                and cost_type_id = 3704
                and effective_date BETWEEN :start_date AND :end_date
        ) as provider_bills
"

set sql "
	select	
		child.project_id as child_id,
		child.project_type_id,
		child.project_status_id,
		child.project_name,
		child.project_nr,
		child.parent_id,
		(select im_name_from_id(child.project_lead_id)) as project_lead_name,
		child.percent_completed,
		child.project_budget,
		child.start_date::date as child_start_date,
		child.end_date::date as child_end_date,
		child.cost_invoices_cache,
		child.cost_timesheet_logged_cache,
		(
        		select 	sum(t.planned_units)
			from	im_projects s_parent, im_projects s_child
				LEFT OUTER JOIN im_timesheet_tasks t ON (s_child.project_id = t.task_id)
		        where
		                s_parent.project_id = child.project_id and
		                s_child.project_status_id not in ([im_project_status_deleted]) and
		                s_child.tree_sortkey between s_parent.tree_sortkey and tree_right(s_parent.tree_sortkey)
		) as project_budget_hours,
		tree_level(child.tree_sortkey) - tree_level(p.tree_sortkey) as tree_level,
		c.company_id,
		c.company_name,
		c.company_path as company_nr,
		eb.amount as total_expenses_billable,
                enb.amount as total_expenses_not_billable,
		h.hours as direct_hours,
		(select count(*) from im_projects where parent_id = child.project_id and project_type_id <> 100) as no_project_childs,
		$provider_bill_select
	from	
		im_projects p,
		im_companies c,
		im_projects child
		LEFT OUTER JOIN (
			select 
				sum(hours) as hours, 
				project_id 
			from 
				im_hours 
			where 
                        	day >= to_date(:start_date::text, 'YYYY-MM-DD') and
                          	day <= to_date(:end_date::text, 'YYYY-MM-DD')
			group by 
				project_id
		) h ON (child.project_id = h.project_id) 
                LEFT OUTER JOIN (
                        select
                                project_id,
                                sum(c.amount * e.reimbursable / 100) as amount
                        from
                                im_costs c,
				im_expenses e
			where 
				c.effective_date >= to_date(:start_date::text, 'YYYY-MM-DD') 
                                and c.effective_date <= to_date(:end_date::text, 'YYYY-MM-DD')
                                and c.cost_type_id = 3720
				and c.cost_id = e.expense_id
				and e.billable_p = 't'	
                        group by 
				project_id
                ) eb ON (child.project_id = eb.project_id)
                LEFT OUTER JOIN (
                        select
                                project_id,
                                sum(c.amount * e.reimbursable / 100) as amount
                        from
                                im_costs c,
				im_expenses e
			where 
				c.effective_date >= to_date(:start_date::text, 'YYYY-MM-DD') 
                                and c.effective_date <= to_date(:end_date::text, 'YYYY-MM-DD')
                                and c.cost_type_id = 3720
				and c.cost_id = e.expense_id
				and e.billable_p = 'f'	
                        group by 
				project_id
                ) enb ON (child.project_id = enb.project_id)
	where
		p.parent_id is null
		and child.tree_sortkey between p.tree_sortkey and tree_right(p.tree_sortkey)
		and (
			child.project_id = p.project_id
			OR child.parent_id in ([join $opened_projects ","])
		)
		and p.company_id = c.company_id 
		$where_clause
	order by 
		c.company_id
"

db_multirow -extend {level_spacer open_gif} project_list project_list $sql  {

    set project_name "$project_nr $project_name"

    # set no_project_childs 0

    # if {0 == $cost_timesheet_logged_cache} { set cost_timesheet_logged_cache ""}
    if { "" == $direct_hours} { set direct_hours 0 }
    if { "" == $percent_completed } { set percent_completed 0 }
    if { "" == $project_budget_hours } { set project_budget_hours 0 }
    if { "" == $total_expenses_billable } { set total_expenses_billable 0 }
    if { "" == $project_budget } { set project_budget 0 }

    set level_spacer ""
    for {set i 0} {$i < $tree_level} {incr i} { append level_spacer "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" }

    # Open/Close Logic
    set open_p [expr [lsearch $opened_projects $child_id] >= 0]
    if {$open_p} {
	set opened $opened_projects
	if {[info exists project_children($child_id)]} {
	    set rem_from_list $project_children($child_id)
	    lappend rem_from_list $child_id
	} else {
	    set rem_from_list [list $child_id]
	}
	set opened [set_difference $opened_projects $rem_from_list]
	set url [export_vars -base $this_url {project_id customer_id employee_id {opened_projects $opened}}]
	set gif [im_gif "minus_9"]
    } else {
	set opened $opened_projects
	lappend opened $child_id
	set url [export_vars -base $this_url {project_id customer_id employee_id {opened_projects $opened}}]

	ns_log NOTICE "intranet-reporting::project-budget--no_project_childs: $no_project_childs; project_id: $child_id "
	if { 0 != $no_project_childs } {set gif [im_gif "plus_9"]} else {set gif [im_gif "minus_9"]}	

    }

    set open_gif "$level_spacer<a href=\"$url\">$gif</a>"

    if {![info exists project_has_children_p($child_id)] } { 
	set open_gif [im_gif empty21 "" 0 9 9] 
    }

    # ns_log NOTICE "intranet-reporting::project-budget project_type_id: $project_type_id; project_id: $child_id "

}

# multirow_sort_tree project_list child_id parent_id project_name

# ------------------------------------------------------------

# set debug_ouput [list]
# foreach {key value} [array get users] {
#     lappend debug_output $key "->" $value "<br>"
# }
# ad_return_complaint 1 $debug_output

set i 1

set sum_invoices_value 0 
set amount_invoicable_matrix 0 
set amount_costs_staff 0
set total_expenses_billable 0
set total_expenses_not_billable 0
set cost_timesheet_logged_cache 0
set total__amount_costs_staff 0 
set total__cost_timesheet_logged_cache 0
set total__amount_invoicable_matrix 0
set total__target_benefit 0
set total__invoiceable_total_var 0
set total__total_expenses_billable 0
set total__total_expenses_not_billable 0
set total__total_provider_bills 0
set total__sum_invoices_value 0
set total__profit_and_loss_project_var 0
set total__profit_and_loss_one_var 0
set total__profit_and_loss_two_var 0

set err_mess ""

set inner_hours_where ""
if { 0 != $user_id_from_search } { set inner_hours_where "and ho.user_id = $user_id_from_search" }


template::multirow foreach project_list {

   	ds_comment "----------------------------------------------------------------------------------------------------"
   	ds_comment "company_id: $company_id, child_id: $child_id, parent_id: $parent_id, project_name: $project_name"
   	ds_comment "----------------------------------------------------------------------------------------------------"

	# ds_comment "project-budget::set_cost_timesheet_logged_cache: set cost_timesheet_logged_cache to value: $employee_hours_amount "
	# set cost_timesheet_logged_cache $employee_hours_amount
	# ds_comment "set_total_expenses: set total_expenses_billable to value: $employee_costs_billable "
	# set total_expenses_billable $employee_costs_billable
	# ds_comment "set_total_expenses: set total_expenses_not_billable to value: $employee_costs_not_billable "
	# set total_expenses_not_billable $employee_costs_not_billable

	# BAK, otherwise will be overwritten by 2nd sql 
	# set total_expenses_billable_bak $total_expenses_billable
	# set total_expenses_not_billable_bak $total_expenses_not_billable

	set target_benefit 0
	set sql "
		select
			sum(ho.hours) as hours,
			(select hourly_cost from im_employees where employee_id = ho.user_id) as hourly_cost,
        	ho.user_id,
			ho.project_id,
			(select company_id from im_projects where project_id = ho.project_id) as company_id_inner,
			ho.day as calendar_date
		from
			im_hours ho, 
			im_projects p
		where
			ho.project_id in (
        				select  
								children.project_id as sub_project_id
						from    
								im_projects parents,
	                            im_projects children
		                where
        	                     children.tree_sortkey between
								 parents.tree_sortkey
								 and tree_right(parents.tree_sortkey)
								 and parents.project_id = $child_id
		                         UNION
								 select $child_id as sub_project_id
                		)
						and ho.day >= to_date(:start_date::text, 'YYYY-MM-DD')
						and ho.day <= to_date(:end_date::text, 'YYYY-MM-DD')
						and ho.project_id = p.project_id
						$inner_hours_where			
			group by
            	 	ho.user_id,
        	       	hours,
					ho.project_id,
					ho.day
	"
	set sum_hours 0
	db_foreach rec $sql {

		# Sum up hours for this project 
    	set sum_hours [expr $sum_hours + $hours]

    	set costs_staff_rate $hourly_cost

		ds_comment "Hourly rate for user_id: $user_id: $costs_staff_rate "
		
        if { "" == $costs_staff_rate || 0 == $costs_staff_rate } {
			append err_mess [lang::message::lookup "" intranet-reporting.MissingPrice "No price found for user/project:<br>"]
            append err_mess "<a href='/intranet/users/view?user_id=$user_id'>[im_name_from_user_id $user_id]</a> / <a href='/intranet/projects/view?project_id=$project_id'>"
            append err_mess [db_string get_data "select project_name from im_projects where project_id = $project_id" -default "$project_id"]
            append err_mess "</a><br><br>"
		} else {
            set amount_costs_staff [expr $amount_costs_staff + [expr $costs_staff_rate * $hours]]		
		}
	
	}

	# Company Id 
  	template::multirow set project_list $i company_id $company_id

	# Avoid showing multiple company_names in html view  
	if { "html" == $output_format } {
		if {$company_name_saved == $company_name } {set company_name ""} else {set company_name_saved $company_name}
	}

    # Project Id 
    template::multirow set project_list $i project_id $child_id

    # Project Type Id 
    template::multirow set project_list $i project_type_id $project_type_id

    # Project name 
    template::multirow set project_list $i project_name "$project_nr $project_name"

    # Project Manager
    template::multirow set project_list $i project_manager $project_lead_name

    # End Date (Fertigstellung)
    template::multirow set project_list $i end_date [lc_time_fmt $child_end_date "%x" locale]

    # percent_completed (Fortschritt)
	set percent_completed_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $percent_completed+0] $rounding_precision] $format_string $locale]
    template::multirow set project_list $i percent_completed $percent_completed_pretty

	# project_budget_hours
    template::multirow set project_list $i project_budget_hours $project_budget_hours

	# hours_logged
    template::multirow set project_list $i hours_logged $sum_hours

	# deviation_target (project_budget_hours * percent_completed - hours_logged)
	if { "0" == $percent_completed  } {
	    set deviation_target [expr $project_budget_hours - $sum_hours]
	} else {
	    set deviation_target [expr $project_budget_hours * $percent_completed/100 - $sum_hours]
	}
    set deviation_target_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $deviation_target+0] $rounding_precision] $format_string $locale]
    template::multirow set project_list $i deviation_target $deviation_target_pretty
	
	# Projection_hours (hours_logged / project_budget_hours / percent_completed * project_budget_hours)
	# If conditions remain the same, how many hours will be probably needed to finish the project
	if { 0 == $project_budget_hours || 0 == $percent_completed  } {
	    set projection_hours 0
	    template::multirow set project_list $i projection_hours [lang::message::lookup "" intranet-reporting.NotComputable  "Not computable"]
	    set delta_projection_hours_budget 0 
	    template::multirow set project_list $i delta_projection_hours_budget [lang::message::lookup "" intranet-reporting.NotComputable  "Not computable"]
	} else {
	    set projection_hours [expr $sum_hours / ($percent_completed/100.0)] 	    
	    template::multirow set project_list $i projection_hours [lc_numeric [im_numeric_add_trailing_zeros [expr $projection_hours+0] $rounding_precision] $format_string $locale]
	    set delta_projection_hours_budget [expr $project_budget_hours - $projection_hours]
	    set delta_projection_hours_budget_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $delta_projection_hours_budget+0] $rounding_precision] $format_string $locale]
	    template::multirow set project_list $i delta_projection_hours_budget $delta_projection_hours_budget_pretty
	}

	# project_budget 
	set project_budget_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $project_budget+0] $rounding_precision] $format_string $locale]
    template::multirow set project_list $i project_budget $project_budget_pretty

	# Costs staff 
	set amount_costs_staff_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $amount_costs_staff+0] $rounding_precision] $format_string $locale]

    # Provider Bills
	set amount_provider_bills_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $provider_bills+0] $rounding_precision] $format_string $locale]

    # Costs Material (billable)
    set total_expenses_billable_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $total_expenses_billable+0] $rounding_precision] $format_string $locale]
    ds_comment "Expenses (billable): $total_expenses_billable"

	set costs_matrix [expr $amount_invoicable_matrix + $provider_bills + $total_expenses_billable + $amount_costs_staff]
	set costs_matrix_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $costs_matrix+0] $rounding_precision] $format_string $locale]
    template::multirow set project_list $i costs_matrix $costs_matrix_pretty		

	# delta_budget_costs (project_budget * percent_completed - costs_matrix)
    set delta_budget_costs [expr $project_budget * $percent_completed/100 - $costs_matrix]
    set delta_budget_costs_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $delta_budget_costs+0] $rounding_precision] $format_string $locale]
    template::multirow set project_list $i delta_budget_costs $delta_budget_costs_pretty

	# projection_costs (costs_matrix / project_budget / percent_completed * project_budget)
	if { 0 == $project_budget_hours || 0 == $percent_completed  } {
        template::multirow set project_list $i projection_costs [lang::message::lookup "" intranet-reporting.NotComputable  "Not computable"]
	    set projection_costs 0 
    } else {
	    set projection_costs [expr $costs_matrix / ($percent_completed/100.0)]
	    set projection_costs_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $projection_costs+0] $rounding_precision] $format_string $locale]
	    template::multirow set project_list $i projection_costs $projection_costs_pretty
    }

	# delta_budget_projection (project_budget - projection_costs) 
    if { 0 == $projection_costs } {
	    set delta_budget_projection_pretty [lang::message::lookup "" intranet-reporting.NotComputable  "Not computable"]
	} else {
	    set delta_budget_projection [expr $project_budget - $projection_costs]
	    set delta_budget_projection_pretty [lc_numeric [im_numeric_add_trailing_zeros [expr $delta_budget_projection+0] $rounding_precision] $format_string $locale]
	}
        template::multirow set project_list $i delta_budget_projection $delta_budget_projection_pretty

	# If CVS, write inmediately to browser ...  
	if { "csv" == $output_format } {
		if { 1 == $i  } {
		    im_report_write_http_headers -output_format $output_format
		    set title_line "\"Firma\"\t\"Project Nr./Name\"\t\"Schrftl. Best.\"\t\"Projekt Status\"\t\"Personalkosten\"\t\"Selbstkosten\"\t\"Kosten lt. Preis-Matrix\"\t\"Sonstige Kosten (abrechenbar)\"\t"
	            append title_line "\"Sonstige Kosten (nicht abrechenbar\"\t\"Lieferantenrechnungen\"\t\"Anspruch\"\t\"Abgerechnet\"\t\"GuV Project\"\t\"GuV 1\"\t\"GuV 2\"\t\n" 
		    ns_write $title_line 
		}
		set output_row "\"$company_name\"\t" 
		append output_row "\"$project_nr $project_name\"\t"
		append output_row "\"$amount_costs_staff_pretty\"\t"
       	append output_row "\"$target_benefit_pretty\"\t"
	  	if { 100 != $project_type_id } { ns_write $output_row }
	}

	incr i
}

if { "csv" == $output_format && 1 == $i } {
    ad_return_complaint 1  [lang::message::lookup "" intranet-core.NoRecordsFound "No records found"]
}

set total__amount_costs_staff		[lc_numeric [im_numeric_add_trailing_zeros [expr $total__amount_costs_staff+0] $rounding_precision] $format_string $locale]
set total__target_benefit           [lc_numeric [im_numeric_add_trailing_zeros [expr $total__target_benefit+0] $rounding_precision] $format_string $locale]
set total__amount_invoicable_matrix	[lc_numeric [im_numeric_add_trailing_zeros [expr $total__amount_invoicable_matrix+0] $rounding_precision] $format_string $locale]


switch $output_format {
    html {
	template::list::create \
	    -name project_list \
	    -elements $elements
    }
    component_html {
        template::list::create \
	    -name project_list \
            -elements $elements
    }
}

