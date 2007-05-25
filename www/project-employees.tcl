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
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0}
    { company_id:integer 0}
    { user_id:integer 0}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-projects-timesheet"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']


# ------------------------------------------------------------
# Constants

set number_format "999,999.99"



# ------------------------------------------------------------
# Calculate the transitive closure for projects, that is
# sub_project_id => {sub_project_id, parent_1_id, parent_2_id, ...}
# ------------------------------------------------------------

set project_closure_sql "
	select	project_id,
		parent_id
	from	im_projects
"

array set project_closure {}

db_foreach project_closure $project_closure_sql {
    set l [list $project_id]
    if {[info exists project_closure($project_id)] } { set l project_closure($project_id) }

    if {"" != $parent_id} { lappend l $parent_id }
    set project_closure($project_id) $l
}


# ------------------------------------------------------------
# Calculate the sum of hours per project and user
# and store the result in a hash array.
# ------------------------------------------------------------

set hours_sql "
	SELECT 	h.project_id,
		h.user_id,
		SUM(hours) AS hours,
		im_name_from_user_id(h.user_id) AS name
	FROM	im_hours h
	GROUP BY 
		h.project_id, h.user_id
	HAVING SUM(hours)>0
"

array set users {}
array set projects {}


db_foreach hours $hours_sql {
    set users($user_id) $name
    
    foreach parent_id $project_closure($project_id) {
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
    tree_level {
    }
    project_name {
	label "Project Name"
	link_url_eval { 
	    [return "/intranet/projects/view?[export_vars -url { project_id } ]" ]
	}
	html "nowrap"
    }
    cost_invoices_cache { 
	label "Invoices"
    }
    cost_delivery_notes_cache { 
	label "DelNotes" 
    }
    cost_quotes_cache { 
	label "Quotes" 
    }
    cost_bills_cache { 
	label "Bills" 
    }
    cost_expense_logged_cache { 
	label "Expenses" 
    }
    cost_timesheet_logged_cache { 
	label "Timesheet Cost" 
    }
    cost_purchase_orders_cache { 
	label "POs" 
    }
    reported_hours_cache { 
	label "Hours" 
    }
}


# Extend the "elements" list definition by the number of users who logged hours
foreach user_id [array names users] {
    multirow extend project_list "user_$user_id"
    lappend elements "user_$user_id"
    lappend elements [list label $users($user_id) ]
}



# ------------------------------------------------------------

db_multirow project_list project_list "
	select	p.*
	from	im_projects p
	where	parent_id is null
" {
    set project_name "         $project_name"

    if {0 == $cost_invoices_cache} { set cost__cache ""}
    if {0 == $cost_delivery_notes_cache} { set cost_delivery_notes_cache ""}
    if {0 == $cost_quotes_cache} { set cost_quotes_cache ""}
    if {0 == $cost_bills_cache} { set cost_bills_cache ""}
    if {0 == $cost_expense_logged_cache} { set cost_expense_logged_cache ""}
    if {0 == $cost_timesheet_logged_cache} { set cost_timesheet_logged_cache ""}
    if {0 == $cost_purchase_orders_cache} { set cost_purchase_orders_cache ""}
    if {0 == $reported_hours_cache} { set reported_hours_cache ""}

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




