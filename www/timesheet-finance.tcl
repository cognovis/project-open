# /packages/intranet-reporting/www/projects-timesheet.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours
} {
    { level_of_detail 2 }
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0}
    { company_id:integer 0}
    { employee_id:integer,multiple 0}
    { opened_projects "" }
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-timesheet-finance"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']


# Check security. opened_projects should only contain integers.
if {[regexp {[^0-9\ ]} $opened_projects match]} {
        im_security_alert \
            -location "Timesheet Finance Report" \
            -message "Received non-integer value for opened_projects" \
            -value $opened_projects
    return [list]
}


# ------------------------------------------------------------
# Constants & Options

set number_format "999,999.99"

set level_options {1 "Main Project" 2 "Main &amp; Subprojects" 3 "All Details"}

if {0 == $employee_id} { set employee_id [db_list emp_list "select employee_id from im_employees"] }

if {[llength $opened_projects] == 0} { set opened_projects [list 0] }


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

# Maxlevel is 4. Normalize in order to show the right drop-down element
if {$level_of_detail > 4} { set level_of_detail 4 }


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


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/timesheet-finance" {start_date end_date} ]
set current_url [im_url_with_query]


# ------------------------------------------------------------
# Calculate the transitive superprojs for projects, that is
# sub_project_id => {sub_project_id, parent_1_id, parent_2_id, ...}
# ------------------------------------------------------------

set project_superprojs_sql "
	select
		project_id,
		parent_id
	from
		im_projects
"

array set project_parent {}
array set project_has_children_p {}
array set project_direct_children {}

db_foreach project_superprojs $project_superprojs_sql {
    # Setup the project->parent relation
    set project_parent($project_id) $parent_id

    # Determine if a project has children
    set project_has_children_p($parent_id) 1

    # Setup the list of direct children of a project
    if {"" != $parent_id} { 
	set l [list]
	if {[info exists project_direct_children($parent_id)] } { set l $project_direct_children($parent_id) }
	lappend l $project_id
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
	SELECT 	h.project_id,
		h.user_id,
		SUM(hours) AS hours,
		im_name_from_user_id(h.user_id) AS name
	FROM	im_hours h
	WHERE	1=1
		$hours_where
	GROUP BY 
		h.project_id, h.user_id
	HAVING SUM(hours)>0
"

array set users {}
array set projects {}

db_foreach hours $hours_sql {
    set users($user_id) $name
    
    foreach parent_id $project_parents($project_id) {
	if { ![info exists projects($parent_id,$user_id)] } {
	    set projects($parent_id,$user_id) 0
	}
	set projects($parent_id,$user_id) [expr $projects($parent_id,$user_id) + $hours]
    }
}


# ------------------------------------------------------------
# Create the main list
# ------------------------------------------------------------


set elements {
    project_name {
	label "Project Name"
	display_template { 
		<nobr>@project_list.level_spacer;noquote@ 
		@project_list.open_gif;noquote@
		<a href="/intranet/projects/view?project_id=@project_list.project_id@"
			>@project_list.project_name@
		</a>
		</nobr> 
        }
    }
    child_start_date  { 
	label "Start"
    }
    child_end_date  { 
	label "End"
    }
    cost_invoices_cache { 
	label "Invoice"
	html "align right"
    }
    cost_delivery_notes_cache { 
	label "DelNote" 
	html "align right"
    }
    cost_quotes_cache { 
	label "Quote" 
	html "align right"
    }
    cost_bills_cache { 
	label "Bill" 
	html "align right"
    }
    cost_expense_logged_cache { 
	label "Expense"
	html "align right"
    }
    cost_timesheet_logged_cache { 
	label "TimeS" 
	html "align right"
    }
    cost_purchase_orders_cache { 
	label "POs" 
	html "align right"
    }
    reported_hours_cache { 
	label "Hours" 
	html "align right"
    }
}


# Extend the "elements" list definition by the number of users who logged hours
foreach user_id [array names users] {
    multirow extend project_list "user_$user_id"
    lappend elements "user_$user_id"
    lappend elements [list label $users($user_id) html "align right"]
}


# ------------------------------------------------------------

set ttt {
OR child.parent_id in ([join $opened_projects ","]))

		and (child.parent_id is null OR )

}

db_multirow -extend {level_spacer open_gif} project_list project_list "

	select	
		child.project_id,
		child.project_name,
		child.project_nr,
		child.parent_id,

		child.start_date::date as child_start_date,
		child.end_date::date as child_end_date,

		child.cost_invoices_cache,
		child.cost_delivery_notes_cache,
		child.cost_quotes_cache,
		child.cost_bills_cache,
		child.cost_expense_logged_cache,
		child.cost_timesheet_logged_cache,
		child.cost_purchase_orders_cache,
		child.reported_hours_cache,

		tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as tree_level
	from	
		im_projects parent,
		im_projects child
	where
		parent.parent_id is null
		and parent.end_date >= to_date(:start_date, 'YYYY-MM-DD')
		and parent.start_date < to_date(:end_date, 'YYYY-MM-DD')
		and parent.project_status_id not in ([im_project_status_deleted])
		and child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and (
			child.project_id = parent.project_id
			OR child.parent_id in ([join $opened_projects ","])
		)


" {
    set project_name "         $project_name"

    if {0 == $cost_invoices_cache} { set cost_invoices_cache ""}
    if {0 == $cost_delivery_notes_cache} { set cost_delivery_notes_cache ""}
    if {0 == $cost_quotes_cache} { set cost_quotes_cache ""}
    if {0 == $cost_bills_cache} { set cost_bills_cache ""}
    if {0 == $cost_expense_logged_cache} { set cost_expense_logged_cache ""}
    if {0 == $cost_timesheet_logged_cache} { set cost_timesheet_logged_cache ""}
    if {0 == $cost_purchase_orders_cache} { set cost_purchase_orders_cache ""}
    if {0 == $reported_hours_cache} { set reported_hours_cache ""}

    set level_spacer ""
    for {set i 0} {$i < $tree_level} {incr i} { append level_spacer "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" }

    # Open/Close Logic
    set open_p [expr [lsearch $opened_projects $project_id] >= 0]
    if {$open_p} {
	set opened $opened_projects
	
	if {[info exists project_children($project_id)]} {
	    set rem_from_list $project_children($project_id)
	    lappend rem_from_list $project_id
	} else {
	    set rem_from_list [list $project_id]
	}
	set opened [set_difference $opened_projects $rem_from_list]
	set url [export_vars -base $this_url {{opened_projects $opened}}]
	set gif [im_gif "minus_9"]
    } else {
	set opened $opened_projects
	lappend opened $project_id
	set url [export_vars -base $this_url {{opened_projects $opened}}]
	set gif [im_gif "plus_9"]
    }
    
    set open_gif "<a href=\"$url\">$gif</a>"

    if {![info exists project_has_children_p($project_id)]} { 
	set open_gif [im_gif empty21 "" 0 9 9]
    }

}

multirow_sort_tree project_list project_id parent_id project_name



# ------------------------------------------------------------

set i 1

template::multirow foreach project_list {

    foreach user_id [array names users] {
	if { [info exists projects($project_id,$user_id)] } {
	    set hours $projects($project_id,$user_id)
	} else {
	    set hours ""
	}
	
	template::multirow set project_list $i "user_$user_id" $hours

    }
    incr i
}



template::list::create \
    -name project_list \
    -elements $elements




