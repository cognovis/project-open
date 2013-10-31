# /packages/intranet-reporting/www/logged-units-vs-planned-units.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours
} {
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0}
    { customer_id:integer 0}
    { employee_id:multiple 0}
    { opened_projects:multiple "" }
    { display_fields:multiple "direct_hours sum_reported_units sum_planned_units sum_billable_units" }
    { uom_id 0 }
    { project_status_id -1 }
}

# ------------------------------------------------------------
# Security & defaults

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.

if { -1 == $project_status_id } {
    set project_status_id [im_project_status_open]
}

set menu_label "logged_units_vs_planned_units"
set current_user_id [ad_maybe_redirect_for_registration]
set hours_per_day [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerDay" -default 8]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

set read_p t
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


set rounding_precision 2
set locale [lang::user::locale]
set format_string "%0.2f"

# Ugly but effective: Remove list markup to convert param into a list...
regsub -all {\{} $opened_projects "" opened_projects
regsub -all {\}} $opened_projects "" opened_projects
regsub -all {\{} $employee_id "" employee_id
regsub -all {\}} $employee_id "" employee_id

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

# Check security. opened_projects should only contain integers.
if {[regexp {[^0-9\ ]} $employee_id match]} {
    catch {im_security_alert \
	       -location "Timesheet Finance Report" \
	       -message "Received non-integer value for employee_id" \
	       -value $employee_id
    } err
    ad_return_complaint 1 "Invalid argument:<br>employee_id=$employee_id"
    ad_script_abort
}


# ------------------------------------------------------------
# Constants & Options
set uom_hour_id [im_uom_hour]
set uom_day_id [im_uom_day]
set uom_week_id 328

if { 0 == $uom_id } { set uom_id $uom_hour_id }
if { $uom_id != $uom_hour_id && $uom_id != $uom_day_id && $uom_id != $uom_week_id } {
    ad_return_complaint 1 "'Unit of Measure' not supported, please choose between 'Hour', 'Day' and 'Week'"
}

set display_field_options { \
	"customer_name" "Customer Name" \
	"start_date" "Start Date" \
	"end_date" "End Date" \
	"project_nr" "Project Nr" \
	"project_status" "Project Status" \
	"project_type" "Project Type" \
	"direct_hours" "Direct Hours" \
	"reported_hours_cache" "Total Timesheet" \
}

set page_title [lang::message::lookup "" intranet-reporting.Logged_Units_Planned_Units "Logged units vs. planned units \[Beta\]"]
set context_bar [im_context_bar $page_title]
set context ""

if {0 == $employee_id} { set employee_id [db_list emp_list "select employee_id from im_employees"] }

if {[llength $opened_projects] == 0} { set opened_projects [list 0] }


# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date]} {
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

if {"" == $start_date} {
    set start_date "$todays_year-$todays_month-01"
}

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} {
    set end_date "$end_year-$end_month-01"
}

set customer_url "/intranet/companies/view?customer_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/logged-units-vs-planned-units" {start_date end_date} ]
set current_url [im_url_with_query]

# ------------------------------------------------------------
# ------------------------------------------------------------

set criteria [list]
if {"" != $project_id && 0 != $project_id} {
    lappend criteria "p.project_id = :project_id"
}
if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}
if {"" != $project_status_id && 0 != $project_status_id} {
    lappend criteria "p.project_status_id = :project_status_id"
}

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
		sum(hours) AS logged_hours,
		im_name_from_user_id(h.user_id) AS name
	FROM	im_hours h
	WHERE	1=1
		and user_id in (
			select	member_id
			from	group_distinct_member_map
			where	group_id = [im_employee_group_id]
		)
		and h.day >= :start_date::timestamptz
		and h.day < :end_date::timestamptz
		$hours_where
	GROUP BY 
		h.project_id, h.user_id
	HAVING SUM(hours) > 0
"

array set users {}
array set project_hours {}

# It had been suggested to remove this information from the report 
# It is available in a more user friendly form from other reports 
# Let's keep the code in here. Data might be shown differently  
# in another variant of this report to make the report more readable.

# db_foreach hours $hours_sql {
#    set users($user_id) $name
#
#    if { ![info exists projects($hours_project_id,$user_id)] } {
#	set projects($hours_project_id,$user_id) 0
#    }
#    set projects($hours_project_id,$user_id) [expr $projects($hours_project_id,$user_id) + $logged_hours]

#    foreach parent_id $project_parents($hours_project_id) {
#	if { ![info exists projects($parent_id,$user_id)] } {
#	    set projects($parent_id,$user_id) 0
#	}
#	set projects($parent_id,$user_id) [expr $projects($parent_id,$user_id) + $logged_hours]
#    }
#
# }


# ------------------------------------------------------------
# Create the main list
# ------------------------------------------------------------

set elements [list]

if {[lsearch $display_fields "customer_name"] >= 0} {
    lappend elements customer_name
    lappend elements {
	label "Customer"
	display_template { 
	    <a href="/intranet/companies/view?company_id=@project_list.company_id@"
	    >@project_list.company_name@
	    </a>
	}
    }
}
if {[lsearch $display_fields "project_nr"] >= 0} {
    lappend elements project_nr 
    lappend elements {
	label "Project Nr"
	display_template { 
	    <a href="/intranet/projects/view?project_id=@project_list.child_id@"
	    >@project_list.project_nr@
	    </a>
	}
    }
}
lappend elements project_name 
lappend elements {
    label "Project Name"
    display_template { 
		<nobr>@project_list.level_spacer;noquote@ 
		@project_list.open_gif;noquote@
		<a href="/intranet/projects/view?project_id=@project_list.child_id@"
			>@project_list.project_name@
		</a>
		</nobr> 
    }
}

if {[lsearch $display_fields "start_date"] >= 0} {
    lappend elements child_start_date
    lappend elements {
	label "Start"
	display_template { <nobr>@project_list.child_start_date@</nobr> }
    }
}

if {[lsearch $display_fields "end_date"] >= 0} {
    lappend elements child_end_date
    lappend elements {
	label "End"
	display_template { <nobr>@project_list.child_end_date@</nobr> }
    }
}

if {[lsearch $display_fields "reported_hours_cache"] >= 0} {
    lappend elements reported_hours_cache
    lappend elements {
	label "Total Units<br>logged" 
	display_template { @project_list.reported_hours_cache@ }
         html "align center"
    }
}

if {[lsearch $display_fields "sum_reported_units"] >= 0} {
    lappend elements sum_reported_units
    lappend elements {
        label "Reported<br>Units"
        display_template { @project_list.sum_reported_units@ }
        html "align center"
    }
}

if {[lsearch $display_fields "sum_planned_units"] >= 0} {
    lappend elements sum_planned_units
    lappend elements {
        label "Planned<br>Units"
        display_template { @project_list.sum_planned_units@ }
	html "align center"
    }
}

if {[lsearch $display_fields "sum_billable_units"] >= 0} {
    lappend elements sum_billable_units
    lappend elements {
        label "Billable<br>Units"
        display_template { @project_list.sum_billable_units@ }
        html "align center"
    }
}

lappend elements balance_rep_plan
lappend elements {
       label "Balance<br/>Reported Units/Planned Units"
       display_template {<if @project_list.balance_rep_plan@ lt 0><b><div style='color:red'>@project_list.balance_rep_plan@</div></b></if><else><b><div>@project_list.balance_rep_plan@</div></b></else>}
       html "align center"
}

lappend elements balance_rep_bill
lappend elements {
       label "Balance<br/>Reported Units/Billable Units"
    display_template {<if @project_list.balance_rep_bill@ lt 0><b><div style='color:red'>@project_list.balance_rep_bill@</div></b></if><else><b><div>@project_list.balance_rep_bill@</div></b></else>}
       html "align center"
}



# Extend the "elements" list definition by the number of users who logged hours
foreach user_id [array names users] {
    multirow extend project_list "user_$user_id"
    lappend elements "user_$user_id"
    lappend elements [list label $users($user_id) html "align right"]
}

# ------------------------------------------------------------

db_multirow -extend {level_spacer open_gif} project_list project_list "
	select	
		child.project_id as child_id,
		child.project_name,
		child.project_nr,
		child.parent_id,
		child.start_date::date as child_start_date,
		child.end_date::date as child_end_date,
		child.reported_hours_cache,
		tree_level(child.tree_sortkey) - tree_level(p.tree_sortkey) as tree_level,
		c.company_id,
		c.company_name,
		c.company_path as company_nr,
		h.hours as direct_hours,
		(select 
			sum(planned_units)
		from 
			im_timesheet_tasks
		where 
			task_id in (
				select 
					p_child.project_id 
				from 
					im_projects p_parent,
					im_projects p_child
				where 
					p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
					and p_parent.project_id = child.project_id
			)
			and uom_id = 320
		) as sum_planned_hours,
                (select
                        sum(planned_units)
                from
                        im_timesheet_tasks
                where
                        task_id in (
                                select
                                        p_child.project_id
                                from
                                        im_projects p_parent,
                                        im_projects p_child
                                where
                                        p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                        and p_parent.project_id = child.project_id
                        )
                        and uom_id = 321
                ) as sum_planned_days,
                (select
                        sum(planned_units)
                from
                        im_timesheet_tasks
                where
                        task_id in (
                                select
                                        p_child.project_id
                                from
                                        im_projects p_parent,
                                        im_projects p_child
                                where
                                        p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                        and p_parent.project_id = child.project_id
                        )
                        and uom_id = 328
                ) as sum_planned_weeks,

                (select
                        sum(billable_units)
                from
                        im_timesheet_tasks
                where
                        task_id in (
                                select
                                        p_child.project_id
                                from
                                        im_projects p_parent,
                                        im_projects p_child
                                where
                                        p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                        and p_parent.project_id = child.project_id
                        )
                        and uom_id = 320
                ) as sum_billable_hours,
                (select
                        sum(billable_units)
                from
                        im_timesheet_tasks
                where
                        task_id in (
                                select
                                        p_child.project_id
                                from
                                        im_projects p_parent,
                                        im_projects p_child
                                where
                                        p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                        and p_parent.project_id = child.project_id
                        )
                        and uom_id = 321
                ) as sum_billable_days,
                (select
                        sum(billable_units)
                from
                        im_timesheet_tasks
                where
                        task_id in (
                                select
                                        p_child.project_id
                                from
                                        im_projects p_parent,
                                        im_projects p_child
                                where
                                        p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
                                        and p_parent.project_id = child.project_id
                        )
                        and uom_id = 328
                ) as sum_billable_weeks, 
		0 as balance_rep_plan,
		0 as balance_rep_bill,
		0 as sum_planned_units,
		0 as sum_billable_units,
		0 as sum_reported_units
	from	
		im_projects p,
		im_companies c,
		im_projects child 
			LEFT OUTER JOIN (
				select sum(hours) as hours, project_id 
				from im_hours 
				group by project_id
			) h ON (child.project_id = h.project_id)
	where
		p.parent_id is null
		and child.tree_sortkey between p.tree_sortkey and tree_right(p.tree_sortkey)
		and (
			child.project_id = p.project_id
			OR child.parent_id in ([join $opened_projects ","])
		)
		and p.company_id = c.company_id
		$where_clause
" {
    set project_name "	 $project_name"

    if {0 == $reported_hours_cache} { set reported_hours_cache ""}
    if {0 == $direct_hours} { set direct_hours ""}

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
	set gif [im_gif "plus_9"]
    }

    set open_gif "<a href=\"$url\">$gif</a>"
    if {![info exists project_has_children_p($child_id)]} { set open_gif [im_gif empty21 "" 0 9 9] }

}

multirow_sort_tree project_list child_id parent_id project_name

# ------------------------------------------------------------

set out ""
set i 1

set sum_planned_hours 0 
set sum_billable_hours 0
set sum_planned_units 0
set sum_billable_units 0

template::multirow foreach project_list {

    if { "" == $reported_hours_cache } { set reported_hours_cache 0 }    

    # foreach user_id [array names users] {
    #	if { [info exists projects($child_id,$user_id)] } {
    #	    set hours [expr $projects($child_id,$user_id)]
    #	} else {
    #	    set hours ""
    #	}
    #	template::multirow set project_list $i "user_$user_id" $hours
    # }

    # Days to hours 
    if { "" != $sum_planned_days } {
	set sum_planned_hours [expr $sum_planned_hours + [expr $sum_planned_days * $hours_per_day]]
    }
    if { "" != $sum_planned_weeks } {
        set sum_planned_hours [expr $sum_planned_hours + [expr $sum_planned_weeks * 5 * $hours_per_day]]
    }

    # Weeks to hours 
    if { "" != $sum_billable_days } {
        set sum_billable_hours [expr $sum_billable_hours + [expr $sum_billable_days * $hours_per_day]]
    }
    if { "" != $sum_billable_weeks } {
        set sum_billable_hours [expr $sum_billable_hours + [expr $sum_billable_weeks * 5 * $hours_per_day]]
    }

    # Check for empty 
    if { "" == $sum_planned_hours } { set sum_planned_hours 0 }
    if { "" == $sum_billable_hours } { set sum_billable_hours 0 }

    # Now from hours to target unit 
    if { $uom_id == $uom_hour_id } {
	set sum_planned_units $sum_planned_hours
	set sum_billable_units $sum_billable_hours	
	set sum_reported_units $reported_hours_cache
    } elseif {$uom_id == $uom_day_id} {
	set sum_planned_units [expr $sum_planned_hours / $hours_per_day]
	set sum_billable_units [expr $sum_billable_hours / $hours_per_day]
	set sum_reported_units [expr $reported_hours_cache / $hours_per_day]
    } elseif { $uom_id == $uom_week_id} {
	set sum_planned_units [expr [expr $sum_planned_hours / $hours_per_day] / 5]
	set sum_billable_units [expr [expr $sum_billable_hours / $hours_per_day] /5]
	set sum_reported_units [expr [expr $reported_hours_cache / $hours_per_day] /5]
    } else {
	    ad_return_complaint 1 "Unit of Measure '$uom_id' not supported by this report. Supported are: $uom_hour_id, $uom_day_id, $uom_week_id"
    }

    if { "" == $sum_planned_units } { set sum_planned_units 0 }
    if { "" == $sum_reported_units } { set sum_reported_units 0 }

    set balance_rep_plan [expr $sum_planned_units - $sum_reported_units]
	set balance_rep_bill [expr $sum_billable_units - $sum_reported_units]

    # Formatting 
    set sum_planned_units [lc_numeric [im_numeric_add_trailing_zeros [expr $sum_planned_units+0] $rounding_precision] $format_string $locale]
    set sum_billable_units [lc_numeric [im_numeric_add_trailing_zeros [expr $sum_billable_units+0] $rounding_precision] $format_string $locale]
    set sum_reported_units [lc_numeric [im_numeric_add_trailing_zeros [expr $sum_reported_units+0] $rounding_precision] $format_string $locale]
    set balance_rep_plan [lc_numeric [im_numeric_add_trailing_zeros [expr $balance_rep_plan+0] $rounding_precision] $format_string $locale]
    set balance_rep_bill [lc_numeric [im_numeric_add_trailing_zeros [expr $balance_rep_bill+0] $rounding_precision] $format_string $locale]

    set reported_hours_cache [lc_numeric [im_numeric_add_trailing_zeros [expr $reported_hours_cache+0] $rounding_precision] $format_string $locale]
    
    incr i
}

template::list::create \
    -name project_list \
    -elements $elements 

