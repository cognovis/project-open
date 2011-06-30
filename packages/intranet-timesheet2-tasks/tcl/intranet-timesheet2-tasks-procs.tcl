# /packages/intranet-timesheet2-tasks/tcl/intranet-timesheet2-tasks.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
}

# ----------------------------------------------------------------------
# Category Constants
# ----------------------------------------------------------------------

# Task Status
# 9600-9649    Intranet Timesheet Task Status
#
ad_proc -public im_timesheet_task_status_active { } { return 9600 }
ad_proc -public im_timesheet_task_status_inactive { } { return 9602 }
ad_proc -public im_timesheet_task_status_closed { } { return 9601 }

# Task Type
# 9500-9549    Timesheet Task Type
#
ad_proc -public im_timesheet_task_type_standard { } { return 9500 }

# Relationship between tasks:
# 9650-9699    Intranet Timesheet Task Dependency Type
#
# For GanttProject:
ad_proc -public im_timesheet_task_dependency_type_depends { } { return 9650 }
ad_proc -public im_timesheet_task_dependency_type_subtask { } { return 9652 }
#
# For MS-Project
ad_proc -public im_timesheet_task_dependency_type_ff { } { return 9660 }
ad_proc -public im_timesheet_task_dependency_type_fs { } { return 9662 }
ad_proc -public im_timesheet_task_dependency_type_sf { } { return 9664 }
ad_proc -public im_timesheet_task_dependency_type_ss { } { return 9666 }


# Task Sheduling
# 9700-9719    Intranet Timesheet Task Scheduling Type
#
ad_proc -public im_timesheet_task_scheduling_type_asap { } { return 9700 }
ad_proc -public im_timesheet_task_scheduling_type_alap { } { return 9701 }
ad_proc -public im_timesheet_task_scheduling_type_mso { } { return 9702 }
ad_proc -public im_timesheet_task_scheduling_type_mfo { } { return 9703 }
ad_proc -public im_timesheet_task_scheduling_type_snet { } { return 9704 }
ad_proc -public im_timesheet_task_scheduling_type_snlt { } { return 9705 }
ad_proc -public im_timesheet_task_scheduling_type_fnet { } { return 9706 }
ad_proc -public im_timesheet_task_scheduling_type_fnlt { } { return 9707 }


ad_proc -public im_timesheet_task_dependency_hardness_type_hard { } { return 9550 }


ad_proc -public im_package_timesheet_task_id {} {
    Returns the package id of the intranet-timesheet2-tasks module
} {
    return [util_memoize "im_package_timesheet_task_id_helper"]
}

ad_proc -private im_package_timesheet_task_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-timesheet2-tasks'
    } -default 0]
}



# ----------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_task_permissions {user_id task_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $project_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    # Search for the closest "real" project
    set ctr 0
    set project_id $task_id
    set project_type_id [db_string ttype "select project_type_id from im_projects where project_id = :project_id" -default 0]
    while {([im_project_type_task] == $project_type_id) && ("" != $project_id) && ($ctr < 100)} {
	set project_id [db_string ttype "select parent_id  from im_projects where project_id = :project_id" -default 0]
	set project_type_id [db_string ttype "select project_type_id from im_projects where project_id = :project_id" -default 0]
	incr ctr
    }

    set result [im_project_permissions $user_id $project_id view read write admin]
    return $result
}



# ----------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------

ad_proc -private im_timesheet_task_type_options { 
    {-include_empty 1} 
} {
    set options [db_list_of_lists task_type_options "
        select	category, category_id
        from	im_categories
	where	category_type = 'Intranet Timesheet Task Type' and
		category_id in ([join [im_sub_categories [im_project_type_task]] ","]) and
		(enabled_p is null OR enabled_p = 't')
    "]
    if {0 == [llength $options]} { set options [linsert $options 0 [list [im_category_from_id [im_project_type_task]] [im_project_type_task]]] }
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -private im_timesheet_task_status_options { {-include_empty 1} } {

    set options [db_list_of_lists task_status_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Timesheet Task Status' and
		(enabled_p is null OR enabled_p = 't')
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}



# ----------------------------------------------------------------------
# Task List Page Component
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_task_list_component {
    {-debug 0}
    {-view_name "im_timesheet_task_list"} 
    {-view_type ""}
    {-order_by ""} 
    {-restrict_to_type_id 0} 
    {-restrict_to_status_id 0} 
    {-restrict_to_material_id 0} 
    {-restrict_to_project_id 0} 
    {-restrict_to_project_status_ids ""} 
    {-restrict_to_mine_p "all"} 
    {-restrict_to_with_member_id ""} 
    {-restrict_to_cost_center_id ""} 
    {-max_entries_per_page 50} 
    {-export_var_list {} }
    -current_page_url 
    -return_url 
} {
    Creates a HTML table showing a table of Tasks 
} {
    # ---------------------- Security - Show the comp? -------------------------------
    set user_id [ad_get_user_id]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    
    set include_subprojects 0
    
    # Is this a "Consulting Project"?
    if {0 != $restrict_to_project_id} {
        if {![im_project_has_type $restrict_to_project_id "Consulting Project"]} { return "" }
    }
    
    if {"" == $order_by} { 
        set order_by [parameter::get_from_package_key -package_key intranet-timesheet2-tasks -parameter TaskListDetailsDefaultSortOrder -default "sort_order"] 
    }
    
    # URL to toggle open/closed tree
    set open_close_url "/intranet/biz-object-tree-open-close"    
    
    # Check vertical permissions - Is this user allowed to see TS stuff at all?
    if {![im_permission $user_id "view_timesheet_tasks"]} { return "" }
    
    # Check if the user can see all timesheet tasks
    if {![im_permission $user_id "view_timesheet_tasks_all"]} { set restrict_to_mine_p "mine" }
    
    # Check horizontal permissions -
    # Is the user allowed to see this project?
    im_project_permissions $user_id $restrict_to_project_id view read write admin
    if {!$read && ![im_permission $user_id view_timesheet_tasks_all]} { return ""}
    
    # Is the current user allowed to edit the timesheet task hours?
    set edit_task_estimates_p [im_permission $user_id edit_timesheet_task_estimates]
    
    # ---------------------- Defaults ----------------------------------
    
    # Get parameters from HTTP session
    # Don't trust the container page to pass-on that value...
    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }
    
    # Get the start_idx in case of pagination
    set start_idx [ns_set get $form_vars "task_start_idx"]
    if {"" == $start_idx} { set start_idx 0 }
    set end_idx [expr $start_idx + $max_entries_per_page - 1]
    
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set date_format "YYYY-MM-DD"
    
    set timesheet_report_url "/intranet-timesheet2-tasks/report-timesheet"
    set current_url [im_url_with_query]
    
    if {![info exists current_page_url]} { set current_page_url [ad_conn url] }
    if {![exists_and_not_null return_url]} { set return_url $current_url }
    
    # Get the "view" (=list of columns to show)
    set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]
    if {0 == $view_id} {
        ns_log Error "im_timesheet_task_component: we didn't find view_name=$view_name"
        set view_id [db_string get_view_id "select view_id from im_views where view_name='im_timesheet_task_list'"]
    }
    if {$debug} { ns_log Debug "im_timesheet_task_component: view_id=$view_id" }
    
    
    # ---------------------- Get Columns ----------------------------------
    # Define the column headers and column contents that
    # we want to show:
    #
    set column_headers [list]
    set column_vars [list]
    set admin_links [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]
    
    set column_sql "
	select	*
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by sort_order
    "
    set col_span 0
    db_foreach column_list_sql $column_sql {
        if {"" == $visible_for || [eval $visible_for]} {
            lappend column_headers "$column_name"
            lappend column_vars "$column_render_tcl"
            lappend admin_links "<a href=[export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}] target=\"_blank\"><span class=\"icon_wrench_po\">[im_gif wrench]</span></a>"
            
            if {"" != $extra_select} { lappend extra_selects $extra_select }
            if {"" != $extra_from} { lappend extra_froms $extra_from }
            if {"" != $extra_where} { lappend extra_wheres $extra_where }
        }
        incr col_span
    }
    if {$debug} { ns_log Debug "im_timesheet_task_component: column_headers=$column_headers" }
    
    
    if {[string is integer $restrict_to_cost_center_id] && $restrict_to_cost_center_id > 0} {
        lappend extra_wheres "(t.cost_center_id is null or t.cost_center_id = :restrict_to_cost_center_id)"
    }
    
    
    # -------- Compile the list of parameters to pass-through-------
    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }
    
    set bind_vars [ns_set create]
    foreach var $export_var_list {
        upvar 1 $var value
        if { [info exists value] } {
            ns_set put $bind_vars $var $value
            if {$debug} { ns_log Debug "im_timesheet_task_component: $var <- $value" }
        } else {
            set value [ns_set get $form_vars $var]
            if {![string equal "" $value]} {
                ns_set put $bind_vars $var $value
                if {$debug} { ns_log Debug "im_timesheet_task_component: $var <- $value" }
            }
        }
    }
    
    ns_set delkey $bind_vars "order_by"
    ns_set delkey $bind_vars "task_start_idx"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
        set key [ns_set key $bind_vars $i]
        set value [ns_set value $bind_vars $i]
        if {![string equal $value ""]} {
            lappend params "$key=[ns_urlencode $value]"
        }
    }
    set pass_through_vars_html [join $params "&"]
    
    
    # ---------------------- Format Header ----------------------------------
    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]
    
    # Format the header names with links that modify the
    # sort order of the SQL query.
    #
    set col_ctr 0
    set admin_link ""
    set table_header_html ""
    foreach col $column_headers {
        set cmd_eval ""
        if {$debug} { ns_log Debug "im_timesheet_task_component: eval=$cmd_eval $col" }
        set cmd "set cmd_eval $col"
        eval $cmd
        regsub -all " " $cmd_eval "_" cmd_eval_subs
        set cmd_eval [lang::message::lookup "" intranet-timesheet2-tasks.$cmd_eval_subs $cmd_eval]
        if {$user_is_admin_p} { set admin_link [lindex $admin_links $col_ctr] }
        append table_header_html "  <th class=rowtitle>$cmd_eval$admin_link</th>\n"
        incr col_ctr
    }
    
    set table_header_html "
	<thead>
	    <tr class=tableheader>
		$table_header_html
	    </tr>
	</thead>
    "
    
    # ---------------------- Calculate the Children's restrictions -------------------------
    set criteria [list]
    set task_criteria [list]
    if {[string is integer $restrict_to_status_id] && $restrict_to_status_id > 0} {
        lappend extra_wheres "(t.task_status_id in ([join [im_sub_categories $restrict_to_status_id] ","]) or t.task_status_id is null)"
    }

    # Make it possible to restrict the display to only e.g. open project's tasks
    set project_status_sub_categories [list]
    foreach restrict_to_project_status_id $restrict_to_project_status_ids {
        if {[string is integer $restrict_to_project_status_id] && $restrict_to_project_status_id > 0} {
            foreach category_id [im_sub_categories $restrict_to_project_status_id] {
                lappend project_status_sub_categories $category_id
            }
        }
    }
    if {$project_status_sub_categories ne ""} {
        lappend extra_wheres "parent.project_status_id in ([join $project_status_sub_categories ","])"
        lappend extra_wheres "(child.project_status_id in ([join $project_status_sub_categories ","]) or child.project_type_id = 100)"
    }
    
    if {"mine" == $restrict_to_mine_p} {
        lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = [ad_get_user_id])"
    }
    
    if {[string is integer $restrict_to_with_member_id] && $restrict_to_with_member_id > 0} {
        lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :restrict_to_with_member_id)"
    }
    
    if {[string is integer $restrict_to_type_id] && $restrict_to_type_id > 0} {
        lappend extra_wheres "(t.task_type_id in ([join [im_sub_categories $restrict_to_type_id] ","]) or t.task_type_id is null)"
    }
    
    set restriction_clause [join $criteria "\n\tand "]
    if {"" != $restriction_clause} { 
        set restriction_clause "and $restriction_clause" 
    }
    
    
    set extra_select [join $extra_selects ",\n\t"]
    if { ![empty_string_p $extra_select] } { set extra_select ",\n\t$extra_select" }
    
    set extra_from [join $extra_froms ",\n\t"]
    if { ![empty_string_p $extra_from] } { set extra_from ",\n\t$extra_from" }
    
    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_where] } { set extra_where "and \n\t$extra_where" }
    
    
    # ---------------------- Inner Permission Query -------------------------
    
    # Check permissions for showing subprojects
    set child_perm_sql "
			select	p.* 
			from	im_projects p,
				acs_rels r 
			where	r.object_id_one = p.project_id and 
				r.object_id_two = :user_id
				$restriction_clause"

    if {[im_permission $user_id "view_projects_all"] || [im_permission $user_id "view_timesheet_tasks_all"]} { 
	set child_perm_sql "
			select	p.*
			from	im_projects p 
			where	1=1
				$restriction_clause"
    }

    set parent_perm_sql "
			select	p.*
			from	im_projects p,
				acs_rels r
			where	r.object_id_one = p.project_id and 
				r.object_id_two = :user_id 
				$restriction_clause"

    if {[im_permission $user_id "view_projects_all"]} {
        set parent_perm_sql "
			select	p.*
			from	im_projects p
			where	1=1
				$restriction_clause"
    }

    # ---------------------- Get the SQL Query -------------------------
    
    # Check if the table im_gantt_projects exists, and add it to the query
    if {[db_table_exists im_gantt_projects]} {
        set gp_select "gp.*,"
        set gp_from "left outer join im_gantt_projects gp on (gp.project_id = child.project_id)"
    } else {
        set gp_select ""
        set gp_from ""
    }
    
    # Sorting: Create a sort_by_clause that returns a "sort_by_value".
    # This value is used to sort the hierarchical multirow.
    switch $order_by {
        sort_order { 
            # Order like the imported Gantt diagram (GanttProject or MS-Project)
            set order_by_clause "child.sort_order" 
        }
        start_date { 
            # Order by which tasks starts first
            set order_by_clause "child.start_date" 
        }
        project_name { 
            set order_by_clause "lower(child.project_name)" 
        }
        project_nr { 
            set order_by_clause "lower(child.project_nr)" 
        }
        default {
            set order_by_clause "''" 
        }
    }
    
    #    ad_return_complaint 1 "o='$order_by', clause='$order_by_clause'"
    
    
    set sql "
	select
		t.*,
		to_char(planned_units, '9999999.0') as planned_units,
		to_char(billable_units, '9999999.0') as billable_units,
		(	select	coalesce(sum(planned_units),0)
			from	im_projects sp,
				im_timesheet_tasks stt
			where	sp.project_id = stt.task_id and
				sp.tree_sortkey between child.tree_sortkey and tree_right(child.tree_sortkey)
		) as planned_units_subtotal,
		(	select	coalesce(sum(billable_units),0)
			from	im_projects sp,
				im_timesheet_tasks stt
			where	sp.project_id = stt.task_id and
				sp.tree_sortkey between child.tree_sortkey and tree_right(child.tree_sortkey)
		) as billable_units_subtotal,
		gp.*,
		child.*,
		child.project_nr as task_nr,
		child.project_name as task_name,
		t.task_status_id as task_status_id,
        im_category_from_id(t.task_status_id) as task_status,
		child.project_type_id as task_type_id,
		child.project_id as child_project_id,
		child.parent_id as child_parent_id,
		im_category_from_id(t.uom_id) as uom,
		im_material_nr_from_id(t.material_id) as material_nr,
		to_char(child.percent_completed, '999990.9') as percent_completed_rounded,
		cc.cost_center_name,
		cc.cost_center_code,
		child.project_id as subproject_id,
		child.project_nr as subproject_nr,
		child.project_name as subproject_name,
		t.task_status_id as subproject_status_id,
		im_category_from_id(t.task_status_id) as subproject_status,
		im_category_from_id(child.project_type_id) as subproject_type,
		tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as subproject_level,
		$order_by_clause as order_by_value
		$extra_select
	from
		($parent_perm_sql) parent,
		($child_perm_sql) child
		left outer join im_timesheet_tasks t on (t.task_id = child.project_id)
		left outer join im_gantt_projects gp on (gp.project_id = child.project_id)
		left outer join im_cost_centers cc on (t.cost_center_id = cc.cost_center_id)
		$extra_from
	where
		parent.project_id = $restrict_to_project_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
                child.project_status_id not in ([im_project_status_deleted])
		$extra_where
	order by
		child.tree_sortkey
    "
    
    # Callback before rendering
    upvar page_title page_title
    callback im_timesheet_task_list_before_render -view_name $view_name \
        -view_type $view_type -sql $sql -table_header $page_title
    
    ns_log Debug "Running the renderere for timesheet tasks"
    db_multirow task_list_multirow task_list_sql $sql {
        
        # Perform the following steps in addition to calculating the multirow:
        # The list of all projects
        set all_projects_hash($child_project_id) 1
        # The list of projects that have a sub-project
        set parents_hash($child_parent_id) 1

	ns_log Debug 1 "im_timesheet_task_list_component: id=$project_id, nr=$project_nr, o=$order_by_value"
    }
    
    # Sort the tree according to the specified sort order
    multirow_sort_tree task_list_multirow project_id parent_id order_by_value
    
    # ----------------------------------------------------
    # Determine closed projects and their children
    
    # Store results in hash array for faster join
    # Only store positive "closed" branches in the hash to save space+time.
    # Determine the sub-projects that are also closed.
    set oc_sub_sql "
	select	child.project_id as child_id
	from	im_projects child,
		im_projects parent
	where	parent.project_id in (
			select	ohs.object_id
			from	im_biz_object_tree_status ohs
			where	ohs.open_p = 'c' and
				ohs.user_id = :user_id and
				ohs.page_url = 'default' and
				ohs.object_id in (
					select	child_project_id
					from	($sql) p
				)
			) and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
    "
    db_foreach oc_sub $oc_sub_sql {
        set closed_projects_hash($child_id) 1
    }
    
    # Calculate the list of leaf projects
    set all_projects_list [array names all_projects_hash]
    set parents_list [array names parents_hash]
    set leafs_list [set_difference $all_projects_list $parents_list]
    foreach leaf_id $leafs_list { set leafs_hash($leaf_id) 1 }
    
    if {$debug} { 
        ns_log Debug "timesheet-tree: all_projects_list=$all_projects_list"
        ns_log Debug "timesheet-tree: parents_list=$parents_list"
        ns_log Debug "timesheet-tree: leafs_list=$leafs_list"
        ns_log Debug "timesheet-tree: closed_projects_list=[array get closed_projects_hash]"
        ns_log Debug "timesheet-tree: "
    }
    
    # Render the multirow
    set table_body_html ""
    set ctr 0
    set idx $start_idx
    set old_project_id 0

    # ----------------------------------------------------
    # Render the list of tasks
    template::multirow foreach task_list_multirow {
        
	# Skip this entry completely if the parent of this project is closed
        if {[info exists closed_projects_hash($child_parent_id)]} { continue }
        
        # Replace "0" by "" to make lists better readable
        if {0 == $reported_hours_cache} { set reported_hours_cache "" }
        if {0 == $reported_days_cache} { set reported_days_cache "" }
        
        # Select the "reported_units" depending on the Unit of Measure
        # of the task. 320="Hour", 321="Day". Don't show anything if
        # UoM is not hour or day.
        switch $uom_id {
            320 { set reported_units_cache $reported_hours_cache }
            321 { set reported_units_cache $reported_days_cache }
            default { set reported_units_cache "-" }
        }
        if {$debug} { ns_log Debug "im_timesheet_task_list_component: project_id=$project_id, hours=$reported_hours_cache, days=$reported_days_cache, units=$reported_units_cache" }
        
        set indent_html ""
        set indent_short_html ""
        for {set i 0} {$i < $subproject_level} {incr i} {
            append indent_html "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
            append indent_short_html "&nbsp;&nbsp;&nbsp;"
        }
        
        if {$debug} { ns_log Debug "timesheet-tree: child_project_id=$child_project_id" }
        if {[info exists closed_projects_hash($child_project_id)]} {
            # Closed project
            set gif_html "<a href='[export_vars -base $open_close_url {user_id {page_url "default"} {object_id $child_project_id} {open_p "o"} return_url}]'>[im_gif "plus_9"]</a>"
        } else {
            # So this is an open task - show a "(-)", unless the project is a leaf.
            set gif_html "<a href='[export_vars -base $open_close_url {user_id {page_url "default"} {object_id $child_project_id} {open_p "c"} return_url}]'>[im_gif "minus_9"]</a>"
            if {[info exists leafs_hash($child_project_id)]} { set gif_html "&nbsp;" }
        }
        
        # In theory we can find any of the sub-types of project
        # here: Ticket and Timesheet Task.
        switch $project_type_id {
            100 {
                # Timesheet Task
                set object_url [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $child_project_id} return_url}]
            }
            101 {
                # Ticket
                set object_url [export_vars -base "/intranet-helpdesk/new" {{ticket_id $child_project_id} return_url}]
            }
            default {
                # Project
                set object_url [export_vars -base "/intranet/projects/view" {{project_id $child_project_id} return_url}]
                set planned_units [im_timesheet_task_units -project_id $project_id -type "planned"]
                set billable_units [im_timesheet_task_units -project_id $project_id -type "billable"]
            }
        }
        
        # Table fields for timesheet tasks
        set percent_done_input "<input type=textbox size=3 name=percent_completed.$task_id value=$percent_completed_rounded>"
        set billable_hours_input "<input type=textbox size=3 name=billable_units.$task_id value=$billable_units>"
        if { ![empty_string_p $task_id]} {
            set status_select [im_category_select {Intranet Timesheet Task Status} task_status_id.$task_id $task_status_id]
        } else {
            set status_select ""
        }
        set planned_hours_input "<input type=textbox size=3 name=planned_units.$task_id value=$planned_units>"
        set uom [im_category_from_id $uom_id]
        # Table fields for projects and others (tickets?)
        if {$project_type_id != [im_project_type_task] || !$edit_task_estimates_p} {
            
            # A project doesn't have a "material" and a UoM.
            # Just show "hour" and "default" material here
            set uom_id [im_uom_hour]
            set uom [im_category_from_id $uom_id]
            set material_id [im_material_default_material_id]
            set reported_units_cache $reported_hours_cache
            
            set percent_done_input $percent_completed_rounded
            set billable_hours_input $billable_units_subtotal
            set planned_hours_input $planned_units_subtotal
        }
        
        set task_name "<nobr>[string range $task_name 0 20]</nobr>"
        
        
        # We've got a task.
        # Write out a line with task information
        append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
        foreach column_var $column_vars {
            append table_body_html "\t<td valign=top>"
            set cmd "append table_body_html $column_var"
            eval $cmd
            append table_body_html "</td>\n"
        }
        append table_body_html "</tr>\n"
        
        # Update the counter.
        incr ctr
        if { $max_entries_per_page > 0 && $ctr >= $max_entries_per_page } {
            set more_url [export_vars -base "/intranet-timesheet2-tasks/index" {{project_id $restrict_to_project_id} {view_name "im_timesheet_task_list"}}]
            append table_body_html "
		<tr><td colspan=99>
		<b>[lang::message::lookup "" intranet-timesheet2-tasks.List_cut_at_n_entries "List cut at %max_entries_per_page% entries"]</b>.
		[lang::message::lookup "" intranet-timesheet2-tasks.List_cut_at_n_entries_msg "
			Please click <a href=%more_url%>here</a> for the entire list.
            "]
		</td></tr>\n"
            
            break
        }
    }
    
    # ----------------------------------------------------
    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {
        set new_task_url [export_vars -base "/intranet-timesheet2-tasks/new" {{project_id $restrict_to_project_id} {return_url $current_url}}]
        set table_body_html "
		<tr class=table_list_page_plain>
        <td colspan=$colspan align=left>
			<b>[_ intranet-timesheet2-tasks.There_are_no_active_tasks]</b>
			</td>
		</tr>
		<tr>
			<td colspan=$colspan>
			<ul>
			<li><a href=\"$new_task_url\">[_ intranet-timesheet2-tasks.New_Timesheet_Task]</a>
			</ul>
			</td>
		</tr>
	"
    }
    
    set project_id $restrict_to_project_id

    set total_in_limited 0

    # Deal with pagination
    if {$ctr == $max_entries_per_page && $end_idx < [expr $total_in_limited - 1]} {
        # This means that there are rows that we decided not to return
        # Include a link to go to the next page
        set next_start_idx [expr $end_idx + 1]
        set task_max_entries_per_page $max_entries_per_page
        set next_page_url  "$current_page_url?[export_url_vars project_id task_object_id task_max_entries_per_page order_by]&task_start_idx=$next_start_idx&$pass_through_vars_html"
        set next_page_html "($remaining_items more) <A href=\"$next_page_url\">&gt;&gt;</a>"
    } else {
        set next_page_html ""
    }
    
    if { $start_idx > 0 } {
        # This means we didn't start with the first row - there is
        # at least 1 previous row. add a previous page link
        set previous_start_idx [expr $start_idx - $max_entries_per_page]
        if { $previous_start_idx < 0 } { set previous_start_idx 0 }
        set previous_page_html "<A href=$current_page_url?[export_url_vars project_id]&$pass_through_vars_html&order_by=$order_by&task_start_idx=$previous_start_idx>&lt;&lt;</a>"
    } else {
        set previous_page_html ""
    }
    
    
    # ---------------------- Format the action bar at the bottom ------------
    
    set table_footer_action "

	<table width='100%'>
	<tr>
	<td align=left>
		<a href=\"/intranet-timesheet2-tasks/new?[export_url_vars project_id return_url]\"
		>[_ intranet-timesheet2-tasks.New_Timesheet_Task]</a>
	</td>
	<td align=right>
		<select name=action>
		<option value=save>[lang::message::lookup "" intranet-timesheet2-tasks.Save_Changes "Save Changes"]</option>
		<option value=delete>[_ intranet-timesheet2-tasks.Delete]</option>
		</select>
		<input type=submit name=submit value='[_ intranet-timesheet2-tasks.Apply]'>
	</td>
	</tr>
	</table>
    "
    if {!$write && ![im_permission $user_id "add_timesheet_tasks"]} { set table_footer_action "" }

    set table_footer "
	<tfoot>
	<tr>
	  <td class=rowplain colspan=$colspan align=right>
	    $previous_page_html
	    $next_page_html
	    $table_footer_action
	  </td>
	</tr>
	<tfoot>
    "

    # ---------------------- Join all parts together ------------------------

    # Restore the original value of project_id
    set project_id $restrict_to_project_id

    set component_html "
	<form action=/intranet-timesheet2-tasks/task-action method=POST>
	[export_form_vars project_id return_url]
	<table bgcolor=white border=0 cellpadding=1 cellspacing=1 class=\"table_list_page\">
	  $table_header_html
	  $table_body_html
	  $table_footer
	</table>
	</form>
    "

    return $component_html
}


# ----------------------------------------------------------------------
# Task Info Component
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_task_info_component {
    project_id
    task_id
    return_url
} {
    set html ""

    #
    # small form to add new dependency
    #

    append html "<form action=\"/intranet-timesheet2-tasks/add-dependency\">"
    append html [export_vars -form { return_url task_id } ]
    append html "<select name=dependency_id><option value=\"0\">---</option>"
    db_foreach options "select 
        subtree.project_id AS id,
        (repeat('&nbsp;',tree_level(subtree.tree_sortkey)-tree_level(parent.tree_sortkey)) 
         || subtree.project_nr) AS task_nr
      from 
        im_projects parent, im_projects subtree 
      where subtree.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) 
        and parent.parent_id = :project_id
        AND subtree.project_id != :task_id
      ORDER BY
        subtree.tree_sortkey
    " {
	append html "<option value=\"$id\">$task_nr</option>"
    }
    append html "</select><input type=submit value=\"[lang::message::lookup "" intranet-timesheet2-tasks.Add_Dependency "Add Dependency"]\"></form>"
    
    #
    # the two dependency lists
    #

    foreach {a b info} [list \
	two  one [lang::message::lookup "" intranet-timesheet2-tasks.This_task_depends_on "This task depends on"] \
	one  two [lang::message::lookup "" intranet-timesheet2-tasks.These_tasks_depend_on "These tasks depend on this one"] \
    ] {
	append html "<p>$info:"

	db_multirow delete_task_deps_$a delete_task_deps_$a "
            SELECT
                task_id_one,
                task_id_two,
                task_id_$a AS id,
                project_nr,
                project_name
            from 
                im_timesheet_task_dependencies,im_projects
	    where 
                task_id_$b = :task_id AND dependency_type_id = [im_timesheet_task_dependency_type_depends]
                and task_id_$a = project_id
            "

	template::list::create \
	    -name delete_task_deps_$a \
	    -key task_id_$a \
	    -pass_properties { return_url project_id task_id } \
	    -elements {
		project_nr {
		    label "[_ intranet-timesheet2-tasks.Task_Nr]"
		    link_url_eval { 
			[return "/intranet-timesheet2-tasks/new?[export_vars -url -override {{ task_id $id }} { return_url project_id } ]" ]
		    }
		} 
		project_name {
		    label "[_ intranet-timesheet2-tasks.Task_Name]"
		}
	    } \
	    -bulk_actions [list [_ intranet-core.Delete] "/intranet-timesheet2-tasks/delete-dependency" "Delete selected task dependency"] \
	    -bulk_action_export_vars { return_url project_id task_id } \
	    -bulk_action_method post

	    append html [template::list::render -name delete_task_deps_$a]
    }
    return $html
}

# ----------------------------------------------------------------------
# Task Resources Component
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_task_members_component {
    project_id
    task_id
    return_url
} {
    set html ""

    db_multirow member_list member_list "
        SELECT 
            user_id,
            im_name_from_user_id(user_id) as name,
            percentage,
            im_biz_object_members.rel_id AS rel_id
        from 
            acs_rels,users,im_biz_object_members 
        where 
            object_id_two=user_id and object_id_one=:task_id
            and acs_rels.rel_id=im_biz_object_members.rel_id
            "

    template::list::create \
	-name member_list \
	-key user_id \
	-pass_properties { return_url project_id task_id } \
	-elements {
	    name {
		label "[_ intranet-core.Name]"
		link_url_eval { 
		    [ return "/intranet/users/view?user_id=$user_id" ]
		}
	    }
	    percentage {
		label "[_ intranet-core.Percentage]"
		link_url_eval {
		    [ return "/intranet-timesheet2-tasks/edit-resource?[export_vars -url { return_url rel_id }]" ]
		}
	    }
	} \
	-bulk_actions [list [_ intranet-core.Delete] "/intranet-timesheet2-tasks/delete-resource" "delete resources" ] \
	-bulk_action_export_vars { return_url project_id task_id } \
	-bulk_action_method post
    
    append html [template::list::render -name member_list ]

    return $html
}


# -------------------------------------------------------------------
# Calculate Project Advance
# -------------------------------------------------------------------

ad_proc im_timesheet_project_advance { project_id } {
    Calculate the percentage of advance of the project.
    The query get a little bit more complex because we
    have to take into account the advance of the subprojects.

    This one only works if the current project is a non-task,
    and all of its children are tasks.
    Otherwise we might have a mixed project (translation + consulting).
} {
    # ToDo: Deal with super-tasks that have estimated units themsevles.
    # The planned/advanced units of super-tasks should be ignored and
    # overwritten.

    # Default number of hours per day
    set hours_per_day [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter "TimesheetHoursPerDay" -default 8.0]
    set translation_words_per_hour [parameter::get_from_package_key -package_key "intranet-translation" -parameter "AverageWordsPerHour" -default 300]

    # ----------------------------------------------------------------
    # Get the topmost project
    if {![db_0or1row main_project "
    	select	project_id as main_project_id,
	    	project_type_id
      	from	im_projects
	    where	tree_sortkey = (
			select	tree_root_key(tree_sortkey)
			from	im_projects
			where	project_id = :project_id
		)
    "]} {
        ad_return_complaint 1 "Unable to find parent for project #$project_id"
        ad_script_abort
    }

    # ----------------------------------------------------------------
    # Get the list of all sub-projects, tasks and tickets below the main_project
    # and write into hash arrays
    set hierarchy_sql "
	select
		child.*,
		tree_level(child.tree_sortkey) as tree_level,
		t.*,
		t.uom_id as task_uom_id,
		t.planned_units * child.percent_completed / 100.0 as advanced_units
	from
		im_projects parent,
		im_projects child
		LEFT OUTER JOIN im_timesheet_tasks t ON (child.project_id = t.task_id)
	where
		parent.project_id = :main_project_id and
		child.project_status_id not in ([im_project_status_deleted]) and
		child.tree_sortkey between 
			parent.tree_sortkey and 
			tree_right(parent.tree_sortkey)
	order by
		tree_level DESC
    "
    db_foreach hierarchy $hierarchy_sql {
        if {"" == $percent_completed} { set percent_completed 0 }
        if {"" == $planned_units} { set planned_units 0 }
        if {"" == $billable_units} { set billable_units 0 }
        if {"" == $advanced_units} { set advanced_units 0 }
        
        # Multiply units with 8.0 if UoM = "Day".
        # We need this in order to deal with "mixed" hour/day projects
        if {$task_uom_id == [im_uom_day]} {
            set planned_units [expr $planned_units * $hours_per_day]
            set billable_units [expr $billable_units * $hours_per_day]
            set advanced_units [expr $advanced_units * $hours_per_day]
        }
        
        # Deal with translation projects.
        # Use the fields trans_project_words and trans_project_hours to calculate an
        # estimated of the number of hours included
        if {"" != $trans_project_hours || "" != $trans_project_words} {
            if {"" == $trans_project_hours} { set trans_project_hours 0.0 }
            if {"" == $trans_project_words} { set trans_project_words 0.0 }
            set planned_units [expr $trans_project_hours + $trans_project_words / $translation_words_per_hour]
            set billable_units $planned_units
            set advanced_units [expr $planned_units * $percent_completed / 100.0]
        }
        
        set parent_hash($project_id) $parent_id
        set tree_level_hash($project_id) $tree_level
        set leaf_p_hash($parent_id) 0
        set type_id_hash($project_id) $project_type_id
        set status_id_hash($project_id) $project_status_id
        set planned_units_hash($project_id) $planned_units
        set billable_units_hash($project_id) $billable_units
        set advanced_units_hash($project_id) $advanced_units
        set percent_completed_hash($project_id) $percent_completed
    }

    # ----------------------------------------------------------------
    # Loop through all projects and aggregate the planned and advanced
    # units to the parents
    foreach pid [array names parent_hash] {
        
        # Add the current planned and advanced units to the parent
        set parent_id $parent_hash($pid)
        while {"" != $parent_id } {
            
            set planned_sum 0.0
            set advanced_sum 0.0
            set billable_sum 0.0
            if {[info exists planned_sum_hash($parent_id)]} { set planned_sum $planned_sum_hash($parent_id) }
            if {[info exists planned_sum_hash($pid)]} { set planned_sum [expr $planned_sum + $planned_sum_hash($pid)] }
            if {[info exists advanced_sum_hash($parent_id)]} { set advanced_sum $advanced_sum_hash($parent_id) }
            if {[info exists advanced_sum_hash($pid)]} { set advanced_sum [expr $advanced_sum + $advanced_sum_hash($pid)] }
            if {[info exists billable_sum_hash($parent_id)]} { set billable_sum $billable_sum_hash($parent_id) }
            if {[info exists billable_sum_hash($pid)]} { set billable_sum [expr $billable_sum + $billable_sum_hash($pid)] }
            
            if {[info exists planned_units_hash($pid)]} { 
                set planned $planned_units_hash($pid)
                if {"" == $planned} { set planned 0.0 }
                set planned_sum [expr $planned_sum + $planned]
            }
            if {[info exists advanced_units_hash($pid)]} { 
                set advanced $advanced_units_hash($pid)
                if {"" == $advanced} { set advanced 0.0 }
                set advanced_sum [expr $advanced_sum + $advanced]
            }
            if {[info exists billable_units_hash($pid)]} { 
                set billable $billable_units_hash($pid)
                if {"" == $billable} { set billable 0.0 }
                set billable_sum [expr $billable_sum + $billable]
            }
            set planned_sum_hash($parent_id) $planned_sum
            set advanced_sum_hash($parent_id) $advanced_sum
            set billable_sum_hash($parent_id) $billable_sum
            # fraber 110310: After deleting tasks there are errors in this function, so I added a "catch"...
            set parent_id ""
            catch { set parent_id $parent_hash($parent_id) }
        }
    }

    foreach parid [array names planned_sum_hash] {

        set planned_sum $planned_sum_hash($parid)
        set advanced_sum $advanced_sum_hash($parid)
        set billable_sum $billable_sum_hash($parid)
        
        catch {
            db_dml update_project_advance "
            		update im_projects set
			        percent_completed = (:advanced_sum::numeric / :planned_sum::numeric) * 100
		            where project_id = :parid
	                "
        }

        # Write audit trail
        im_project_audit -project_id $parid
    }
}



ad_proc -public im_timesheet_next_task_nr { 
    -project_id
} {
    Returns the next free task_nr for the given project

    Returns "" if there was an error calculating the number.
} {
    set nr_digits [parameter::get -package_id [im_package_timesheet_task_id] -parameter "TaskNrDigits" -default "4"]

    # ----------------------------------------------------
    # Get project Info
    set project_nr [db_string project_nr "select project_nr from im_projects where project_id = :project_id" -default ""]

    # ----------------------------------------------------
    # Calculate the next Nr by finding out the last one +1

    set sql "
	select	p.project_nr
	from	im_projects p
	where	p.parent_id = 994
		and p.

    "


    # Adjust the position of the start of date and nr in the invoice_nr
    set date_format_len [string length $date_format]
    set nr_start_idx [expr 1+$date_format_len]
    set date_start_idx 1

    set num_check_sql ""
    set zeros ""
    for {set i 0} {$i < $nr_digits} {incr i} {
	set digit_idx [expr 1 + $i]
	append num_check_sql "
		and ascii(substr(p.nr,$digit_idx,1)) > 47
		and ascii(substr(p.nr,$digit_idx,1)) < 58
	"
	append zeros "0"
    }

    set sql "
	select
		trim(max(p.nr)) as last_project_nr
	from (
		 select substr(project_nr, :nr_start_idx, :nr_digits) as nr
		 from   im_projects
		 where  substr(project_nr, :date_start_idx, :date_format_len) = '$todate'
	     ) p
	where   1=1
		$num_check_sql
    "

    set last_project_nr [db_string max_project_nr $sql -default $zeros]
    set last_project_nr [string trimleft $last_project_nr "0"]
    if {[empty_string_p $last_project_nr]} { set last_project_nr 0 }
    set next_number [expr $last_project_nr + 1]

    # ----------------------------------------------------
    # Put together the new project_nr
    set nr_sql "select '$todate' || trim(to_char($next_number,:zeros)) as project_nr"
    set project_nr [db_string next_project_nr $nr_sql -default ""]
    return $project_nr
}


ad_proc -public -callback im_timesheet_task_after_update -impl im_timesheet_tasks {
    {-object_id:required}
} {
    Updates tasks status on im_projects table according with im_timesheet_tasks table.
} {
    set task_status [db_string select_task_status { 
    	SELECT task_status_id FROM im_timesheet_tasks WHERE task_id = :object_id
    } -default ""]
    
    if {[exists_and_not_null task_status]} {
        if {$task_status eq [im_timesheet_task_status_closed]} {
            db_dml update " UPDATE im_projects SET project_status_id = [im_project_status_closed] WHERE project_id = :object_id"
        }
    }
}

ad_proc -public im_timesheet_task_units { 
    -project_id
    {-type "planned"}
} {
    Return the planned hours for a project including the subprojects

    @param project_id Project for which to calculate the planned units
    @param type Billable or planned units
} {
    return [util_memoize [list im_timesheet_task_units_not_cached -project_id $project_id -type $type] 360]
}

ad_proc -public im_timesheet_task_units_not_cached { 
    -project_id
    {-type "planned"}
} {
    Return the planned units for a project including the subprojects not cached

    @param project_id Project for which to calculate the planned units
    @param type Billable or planned units
} {
    return [db_string planned_project_units "select to_char(sum(${type}_units),'9999999.0') from im_timesheet_tasks where task_id in (
    select children.project_id
      from im_projects parent, im_projects children
    where
      children.tree_sortkey between 
      parent.tree_sortkey 
      and tree_right(parent.tree_sortkey)
      and parent.project_id = :project_id
    )" -default ""]
}
