# /packages/intranet-reporting/www/project-tasks.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

    This report has been developed under heavy time/budget constrains and is therfore marked as BETA  
    Code is based on [im_timesheet_task_list_component .. ]
    Please set menu permissions accordingly to avoid missuse 
	To-Do:
		- pagination 
		- additional filters: 
			- show only "my" projects/all projects 
			- only tasks where logged units > planned units 
			- Consulting sub-type
		- optimizing SQL 
		
} {
    report_id:integer,optional
    { task_order_by "Start" }
    { view_name "im_timesheet_task_list_report" }
    { material_id:integer 0 }
    { task_status_id 0 }
    { task_type_id 0 }
    { task_how_many 0 }
    { task_max_entries_per_page 10000 }
    { with_member_id "" }
    { cost_center_id "" }
    { mine_p "" }
    { user_id:integer 0}
    { task_member_id:integer 0}
    { auto_login "" }
    { employee_cost_center_id "" }
    { only_uncompleted_tasks_p ""}
}
	if { "1"==$only_uncompleted_tasks_p } {
		set only_uncompleted_tasks_checked "checked"
	} else {
		set only_uncompleted_tasks_checked ""
	} 
	set report_id 0
	set page_title "Project-Tasks \[BETA\]"
	set current_url "intranet-reporting/project-tasks.tcl"
	set return_url "intranet-reporting/project-tasks.tcl"
	set export_var_list ""
	set user_id [ad_get_user_id]
	set include_subprojects 0
	set max_entries_per_page $task_max_entries_per_page
	set restrict_to_cost_center_id 0
	set order_by "Status"
	set restrict_to_status_id 0
	set restrict_to_mine_p 0
	set restrict_to_with_member_id 0
	set restrict_to_type_id 0

	set menu_label "reporting-project-tasks"
	set current_user_id [ad_maybe_redirect_for_registration]
	set read_p [db_string report_perms "
        	select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
	        from    im_menus m
        	where   m.label = :menu_label
	" -default 'f']

	if {![string equal "t" $read_p]} {
		ad_return_complaint 1 "<li>
		[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
		return
	}

	# Check vertical permissions - Is this user allowed to see TS stuff at all?
	if {![im_permission $user_id "view_timesheet_tasks"]} { return "You are missing the permission to see time sheet tasks (Privilege:'view_timesheet_tasks')" }

	# Check if the user can see all timesheet tasks
	if {![im_permission $user_id "view_timesheet_tasks_all"]} { set restrict_to_mine_p "mine" }

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
	        set view_name "im_timesheet_task_list"
    		set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
	}
	ns_log Notice "im_timesheet_task_component: view_id=$view_id"

	set table_body_html ""


	# ---------------------- Get Columns ----------------------------------
	# Define the column headers and column contents that
	# we want to show:
	#
	set column_headers [list]
	set column_vars [list]
	set extra_selects [list]
	set extra_froms [list]
	set extra_wheres [list]
	set view_order_by_clause ""

	set column_sql "
        	select  *
	        from    im_view_columns
        	where   view_id=:view_id
                	and group_id is null
	        order by sort_order
    	"
	    set col_span 0

	db_foreach column_list_sql $column_sql {
		if {"" == $visible_for || [eval $visible_for]} {
			lappend column_headers "$column_name"
			lappend column_vars "$column_render_tcl"
			if {"" != $extra_select} { lappend extra_selects $extra_select }
			if {"" != $extra_from} { lappend extra_froms $extra_from }
			if {"" != $extra_where} { lappend extra_wheres $extra_where }
			if {"" != $order_by_clause && $order_by == $column_name} { set view_order_by_clause $order_by_clause }
		}
        	incr col_span
	}
	ns_log Notice "im_timesheet_task_component: column_headers=$column_headers"

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
			ns_log Notice "im_timesheet_task_component: $var <- $value"
		} else {
			set value [ns_set get $form_vars $var]
			if {![string equal "" $value]} {
		                ns_set put $bind_vars $var $value
		                ns_log Notice "im_timesheet_task_component: $var <- $value"
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
	set table_header_html ""

	foreach col $column_headers {
        	set cmd_eval ""
		ns_log Notice "im_timesheet_task_component: eval=$cmd_eval $col"
	        set cmd "set cmd_eval $col"
	        eval $cmd
        	regsub -all " " $cmd_eval "_" cmd_eval_subs
		set cmd_eval [lang::message::lookup "" intranet-timesheet2-tasks.$cmd_eval_subs $cmd_eval]
		lappend column_headers $column_name
        	append table_header_html "  <th class=rowtitle>$cmd_eval</th>\n"
	}
	set table_header_html "
        <thead>
            <tr class=tableheader>
                $table_header_html
            </tr>
        </thead>
    	"

	
	set project_type_ids [join [im_sub_categories 2501] ","]


        set main_project_sql "
		select
			p.project_id
		from
			im_projects p
		where
			p.project_type_id in ($project_type_ids) and
			p.project_status_id in (76) and
			p.parent_id is null and
			tree_level(p.tree_sortkey) <= 1
        "

db_foreach main_project_sql $main_project_sql {

	set restrict_to_project_id $project_id

	# Check horizontal permissions -
	# Is the user allowed to see this project?
	# im_project_permissions $user_id $restrict_to_project_id view read write admin
	# if {!$read && ![im_permission $user_id view_timesheet_tasks_all]} { continue }

	# ---------------------- Build the SQL query ---------------------------
	set order_by_clause "order by p.project_nr, t.task_id"
	set order_by_clause_ext "order by project_nr, task_name"

	switch $order_by {
		"Status" {
			set order_by_clause "order by t.task_status_id"
			set order_by_clause_ext "m.task_id"
		}
	}

	# ---------------------- Calculate the Children's restrictions -------------------------
	set criteria [list]

	if {[string is integer $restrict_to_status_id] && $restrict_to_status_id > 0} {
		lappend criteria "p.project_status_id in ([join [im_sub_categories $restrict_to_status_id] ","])"
	}

	if {"mine" == $restrict_to_mine_p} {
		lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = [ad_get_user_id])"
	}

	if {[string is integer $restrict_to_with_member_id] && $restrict_to_with_member_id > 0} {
        	lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :restrict_to_with_member_id)"
	}

	if {[string is integer $restrict_to_type_id] && $restrict_to_type_id > 0} {
		lappend criteria "p.project_type_id in ([join [im_sub_categories $restrict_to_type_id] ","])"
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

	if { 1 == $only_uncompleted_tasks_p } {
		set extra_where " and  \n\t percent_completed_rounded < 100"
	}

	if { "" != $task_member_id } {
		set extra_where " and  \n\t t.task_id in (select object_id_one from acs_rels where object_id_two = :task_member_id)"
	}

	# ---------------------- Inner Permission Query -------------------------

	# Check permissions for showing subprojects
	set child_perm_sql "
                	select  p.*
                        from    im_projects p,
                                acs_rels r
                        where   r.object_id_one = p.project_id and
                                r.object_id_two = :user_id
                                $restriction_clause"

	if {[im_permission $user_id "view_projects_all"] || [im_permission $user_id "view_timesheet_tasks_all"]} {
        	set child_perm_sql "
                        select  p.*
                        from    im_projects p
                        where   1=1
                                $restriction_clause"
	}

	set parent_perm_sql "
                        select  p.*
                        from    im_projects p,
                                acs_rels r
                        where   r.object_id_one = p.project_id and
                                r.object_id_two = :user_id
                                $restriction_clause"

	if {[im_permission $user_id "view_projects_all"]} {
        	set parent_perm_sql "
                        select  p.*
                        from    im_projects p
                        where   1=1
                                $restriction_clause"
	}
    # ---------------------- Get the SQL Query -------------------------
    set sql "
        select
                t.*,
                child.*,
                child.project_nr as task_nr,
                child.project_name as task_name,
                child.project_status_id as task_status_id,
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
                child.project_status_id as subproject_status_id,
                im_category_from_id(child.project_status_id) as subproject_status,
                im_category_from_id(child.project_type_id) as subproject_type,
                tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as subproject_level
                $extra_select
        from
                ($parent_perm_sql) parent,
                ($child_perm_sql) child
                left outer join im_timesheet_tasks t on (t.task_id = child.project_id)
                left outer join im_cost_centers cc on (t.cost_center_id = cc.cost_center_id)
                $extra_from
        where
                parent.project_id = :restrict_to_project_id and
                child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
                $extra_where
        order by
                child.tree_sortkey
    "

	db_multirow task_list_multirow task_list_sql $sql {
		# Perform the following steps in addition to calculating the multirow:
	        # The list of all projects
        	set all_projects_hash($child_project_id) 1
	        # The list of projects that have a sub-project
        	set parents_hash($child_parent_id) 1
	}
	# Sort the tree according to the specified sort order
	multirow_sort_tree task_list_multirow project_id parent_id sort_order


    # ----------------------------------------------------
    # Determine closed projects and their children

    # Store results in hash array for faster join
    # Only store positive "closed" branches in the hash to save space+time.
    # Determine the sub-projects that are also closed.
    set oc_sub_sql "
        select  child.project_id as child_id
        from    im_projects child,
                im_projects parent
        where   parent.project_id in (
                        select  ohs.object_id
                        from    im_biz_object_tree_status ohs
                        where   ohs.open_p = 'c' and
                                ohs.user_id = :user_id and
                                ohs.page_url = 'default' and
                                ohs.object_id in (
                                        select  child_project_id
                                        from    ($sql) p
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

	ns_log Notice "timesheet-tree: all_projects_list=$all_projects_list"
	ns_log Notice "timesheet-tree: parents_list=$parents_list"
	ns_log Notice "timesheet-tree: leafs_list=$leafs_list"
	ns_log Notice "timesheet-tree: closed_projects_list=[array get closed_projects_hash]"
	ns_log Notice "timesheet-tree: "

	# Render the multirow
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

        # ns_log Notice "project-tasks: project_id=$project_id, hours=$reported_hours_cache, days=$reported_days_cache, units=$reported_units_cache"

        set indent_html ""
        set indent_short_html ""
    for {set i 0} {$i < $subproject_level} {incr i} {
	append indent_html "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	append indent_short_html "&nbsp;&nbsp;&nbsp;"
    }

        ns_log Notice "timesheet-tree: child_project_id=$child_project_id"
	if {[info exists closed_projects_hash($child_project_id)]} {
            # Closed project
		set gif_html ""
	} else {
        	# So this is an open task - show a "(-)", unless the project is a leaf.
		set gif_html ""
		# if {[info exists leafs_hash($child_project_id)]} { set gif_html "&nbsp;" }
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
	}
    }

        # Table fields for timesheet tasks
        set percent_done $percent_completed_rounded
        set billable_hours $billable_units
	set status_select $task_status_id
        set planned_hours $planned_units

        # Table fields for projects and others (tickets?)
	if {$project_type_id != [im_project_type_task]} {
	        # A project doesn't have a "material" and a UoM.
	        # Just show "hour" and "default" material here
		set uom_id [im_uom_hour]
		set uom [im_category_from_id $uom_id]
		set material_id [im_material_default_material_id]
	        set reported_units_cache $reported_hours_cache
	        set percent_done $percent_completed_rounded
	        set billable_hours ""
        	set status_select ""
	        set planned_hours ""
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
            break
    	}
}

	# ----------------------------------------------------
	# Show a reasonable message when there are no result rows:
	# if { [empty_string_p $table_body_html] } {
	#        set table_body_html "
        #        <tr class=table_list_page_plain>
        #                <td colspan=$colspan align=left>
	#		<b>[_ intranet-timesheet2-tasks.There_are_no_active_tasks]</b>
        #                </td>
        #        </tr>
        #	"
        # }
    set project_id $restrict_to_project_id

    set total_in_limited 0

        append table_body_html "<tr><td colspan=999>&nbsp;</td></tr>"

}


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
        <td align=left></td>
        <td align=right>
        </td>
        </tr>
        </table>
    "
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

    # ---------------------- Format filter ------------

    # set employee_cost_center_id [db_string current_user_cc "
    #            select  department_id as employee_cost_center_id
    #            from    im_employees
    #            where   employee_id = :user_id
    # " -default ""]
 
    set left_navbar_html "
        <form>
        <table border=0 cellspacing=1 cellpadding=1>
        <tr valign=top>
	    <td>
                <table border=0 cellspacing=1 cellpadding=1>
                <!--
		<tr>
                  <td class=form-label>Start Date</td>
                  <td class=form-widget>
                    <input type=textfield name=start_date value=$start_date>
                  </td>
                </tr>
                <tr>
                  <td class=form-label>End Date</td>
                  <td class=form-widget>
                    <input type=textfield name=end_date value=$end_date>
                  </td>
                </tr>
                <tr>
                  <td class=form-label>Customer</td>
                  <td class=form-widget>
                    [im_company_select company_id $company_id]
                  </td>
                </tr>
                <tr>
                  <td class=form-label>Project Manager</td>
                  <td class=form-widget>
                    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" project_lead_id $project_lead_id]
                  </td>
                </tr>
		-->
                <tr>
                  <td class=form-label>Task Member</td>
                  <td class=form-widget>
                    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" task_member_id $task_member_id]
                  </td>
                </tr>
	        <tr>
	    	    <td class=form-label>[_ intranet-core.Department]:</td>
		    <td class=form-widget>[im_cost_center_select -include_empty 1 -include_empty_name "All" -department_only_p 1 employee_cost_center_id $employee_cost_center_id]</td>
		</tr>
		 <tr>
		        <td class=form-label valign=top>[lang::message::lookup "" intranet-reporting.OnlyUncompletedTasks "Only uncompleted Tasks:"]</td>
			<td class=form-widget valign=top>
	                <input name=only_uncompleted_tasks_p type=checkbox value='1' $only_uncompleted_tasks_checked>
	        </td>
		</tr>

                <tr>
                  <td class=form-label></td>
                  <td class=form-widget><input type=submit value=Submit></td>
                </tr>
                </table>
    	    </td>
     </tr>
     </table>
     </form>
     "
    # ---------------------- Join all parts together ------------------------

    # Restore the original value of project_id
    set project_id $restrict_to_project_id

    set component_html "
    [export_form_vars project_id return_url]
        <table bgcolor=white border=0 cellpadding=1 cellspacing=1 class=\"table_list_page\">
          $table_header_html
          $table_body_html
          $table_footer
        </table>
    "






