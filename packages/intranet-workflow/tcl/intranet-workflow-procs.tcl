# /packages/intranet-workflow/tcl/intranet-workflow-procs.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_workflow_id {} {
    Returns the package id of the intranet-workflow module
} {
    return [util_memoize "im_package_workflow_id_helper"]
}

ad_proc -private im_package_workflow_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-workflow'
    } -default 0]
}

ad_proc -private im_workflow_url {} {
    returns "workflow" or "acs-workflow", depending where the
    acs-workflow module has been mounted.
} {
    set urls [util_memoize "db_list urls {select n.name from site_nodes n, apm_packages p where n.object_id = p.package_id and package_key = 'acs-workflow'}"]
    return [lindex $urls 0]
}


# ----------------------------------------------------------------------
# Aux
# ---------------------------------------------------------------------

ad_proc -public im_workflow_replace_translations_in_string { 
    {-translate_p 1}
    {-locale ""}
    str 
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id [ad_get_user_id]] }
    return [util_memoize [list im_workflow_replace_translations_in_string_helper -translate_p $translate_p -locale $locale $str]]
}

ad_proc -public im_workflow_replace_translations_in_string_helper { 
    {-translate_p 1}
    {-locale ""}
    str 
} {
    # Replace #...# expressions in assignees_pretty with translated version
    set cnt 0
    while {$cnt < 100 && [regexp {^(.*?)#([a-zA-Z0-9_\.\-]*?)#(.*)$} $str match pre trans post]} {
	set str "$pre[lang::message::lookup $locale $trans "'$trans'"]$post"
	incr cnt
    }
    return $str
}


# ----------------------------------------------------------------------
# Start a WF for an object
# ---------------------------------------------------------------------

ad_proc -public im_workflow_start_wf {
    -object_id
    -object_type_id
    {-skip_first_transition_p 0}
} {
    Start a new WF for an object.
} {
    set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :object_type_id" -default ""]
    set wf_exists_p [db_string wf_exists "select count(*) from wf_workflows where workflow_key = :wf_key"]
    set case_id 0

    if {$wf_exists_p} {
	set context_key ""
	set case_id [wf_case_new \
			 $wf_key \
			 $context_key \
			 $object_id
		    ]
	
	# Determine the first task in the case to be executed and start+finisch the task.
	if {1 == $skip_first_transition_p} {
	    im_workflow_skip_first_transition -case_id $case_id
	}
    }
    return $case_id
}

# ----------------------------------------------------------------------
# Selects & Options
# ---------------------------------------------------------------------

ad_proc -public im_workflow_list_options {
    {-include_empty 0}
    {-min_case_count 0}
    {-translate_p 0}
    {-locale ""}
} {
    Returns a list of workflows that satisfy certain conditions
} {
    set min_count_where ""
    if {$min_case_count > 0} { set min_count_where "and count(c.case_id) > 0\n" }
    set options [db_list_of_lists project_options "
	 select
		t.pretty_name,
		w.workflow_key,
		count(c.case_id) as num_cases,
		0 as num_unassigned_tasks
	 from   wf_workflows w left outer join wf_cases c
		  on (w.workflow_key = c.workflow_key and c.state = 'active'),
		acs_object_types t
	 where  w.workflow_key = t.object_type
		$min_count_where
	 group  by w.workflow_key, t.pretty_name
	 order  by t.pretty_name
    "]
    if {$include_empty} { set options [linsert $options "" { "" "" }] }
    return $options
}


ad_proc -public im_workflow_pretty_name {
    workflow_key
} {
    Returns a pretty name for the WF
} {
    if {![regexp {^[a-z0-9_]*$} $workflow_key match]} {
	ad_return_complaint 1 "Bad Workflow Name:<br>must be only alphanumerical.<br>
        Found: '$workflow_key'"
	return "$workflow_key"
    }
    return [util_memoize "db_string pretty_name \"select pretty_name from acs_object_types where object_type = '$workflow_key'\" -default $workflow_key"]
}


ad_proc -public im_workflow_status_options {
    {-translate_p 0}
    {-locale ""}
    {-include_empty 1}
    {-include_empty_name ""}
    workflow_key
} {
    Returns a list of stati (actually: Places) 
    for the given workflow
} {
    #ToDo: Use util_memoize to reduce db-load
    set options [db_list_of_lists project_options "
	 select	place_key,
		place_key
	from	wf_places wfp
	where	workflow_key = :workflow_key
    "]
    if {$include_empty} { set options [linsert $options 0 [list $include_empty_name "" ]] }
    return $options
}

ad_proc -public im_workflow_status_select { 
    {-include_empty 1}
    {-include_empty_name ""}
    {-translate_p 0}
    {-locale ""}
    workflow_key
    select_name
    { default "" }
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the project_types in the system
} {
    if {"" == $workflow_key} {
	ad_return_complaint 1 "im_workflow_status_select:<br>
        Found an empty workflow_key. Please inform your SysAdmin."
        return
    }

    set options [im_workflow_status_options \
	-include_empty $include_empty \
	-include_empty_name $include_empty_name \
	$workflow_key \
    ]

    set result "<select name=\"$select_name\">"
    foreach option $options {
	set value [lindex $option 0]
	set key [lindex $option 1]
	set selected ""
	if {[string equal $default $key]} { set selected "selected" }
        append result "<option value=\"$key\" $selected>$value</option>\n"
    }
    append result "</select>\n"
    return $result
}


# ----------------------------------------------------------------------
# Check if the workflow is stuck with an unassigned task
# ---------------------------------------------------------------------

ad_proc -public im_workflow_stuck_p {
} {
    Checks whether the workflow is "stuck".
    That means: If all of the currently enabled tasks are
    unassigned.
} {
    return 0
}




# ----------------------------------------------------------------------
# Workflow Task List Component
# ---------------------------------------------------------------------

ad_proc -public im_workflow_home_component {
} {
    Creates a HTML table showing all currently active tasks
} {
    set user_id [ad_get_user_id]
    set admin_p [ad_permission_p [ad_conn package_id] "admin"]

    set template_file "packages/acs-workflow/www/task-list"
    set template_path [get_server_root]/$template_file
    set template_path [ns_normalizepath $template_path]

    set package_url "/[im_workflow_url]/"

    set own_tasks [template::adp_parse $template_path [list package_url $package_url type own]]
    set own_tasks "<h3>[lang::message::lookup "" intranet-workflow.Your_Tasks "Your Tasks"]</h3>\n$own_tasks"

    set all_tasks [template::adp_parse $template_path [list package_url $package_url]]
    set all_tasks "<h3>[lang::message::lookup "" intranet-workflow.All_Tasks "All Tasks"]</h3>\n$all_tasks"
    # Disable the "All Tasks" if it doesn't contain any lines.
    if {![regexp {<tr>} $all_tasks match]} { set all_tasks ""}

    set unassigned_tasks ""
    if {$admin_p} {
	set unassigned_tasks [template::adp_parse $template_path [list package_url $package_url type unassigned]]
	set unassigned_tasks "<h3>[lang::message::lookup "" intranet-workflow.Unassigned_Tasks "Unassigned Tasks"]</h3>\n$unassigned_tasks"
    }

    set component_html "
<table class=\"table_container\">
<tr><td>
$own_tasks
$all_tasks
$unassigned_tasks
</td></tr>
</table>
<br>
"

    return $component_html
}



# ----------------------------------------------------------------------
# Graph Procedures
# ---------------------------------------------------------------------



ad_proc -public im_workflow_graph_sort_order {
    workflow_key
} {
    Update the "sort_order" field in wf_transitions
    in order to reflect their distance from "start",
    including places like nodes.
} {
    set arc_sql "
	select *
	from wf_arcs
	where workflow_key = :workflow_key
    "
    db_foreach arcs $arc_sql {
	set distance($place_key) 9999999999
	set distance($transition_key) 9999999999
	switch $direction {
	    in { lappend edges [list $place_key $transition_key] }
	    out { lappend edges [list $transition_key $place_key] }
	}
    }
    
    # Do a breadth-first search trought the graph and search for
    # the shortest path from "start" to the respective node.
    set active_nodes [list start]
    set distance(start) 0
    set cnt 0
    while {[llength $active_nodes] > 0} {
	incr cnt
	ns_log Notice "im_workflow_graph_sort_order: cnt=$cnt, active_nodes=$active_nodes"
	if {$cnt > 10000} {
	    ad_return_complaint 1 "Workflow:<br>
	    Infinite loop in im_workflow_graph_sort_order. <br>
	    Please contact your system administrator"
	    return
	}

	# Extract the first node from active nodes
	set active_node [lindex $active_nodes 0]
	set active_nodes [lrange $active_nodes 1 end]
	foreach edge $edges {
	    set from [lindex $edge 0]
	    set to [lindex $edge 1]
	    # Check if we find and outgoing edge from node
	    if {[string equal $from $active_node]} {
		set dist1 [expr $distance($from) + 1]
		if {$dist1 < $distance($to)} {
		    set distance($to) $dist1
		    ns_log Notice "im_workflow_graph_sort_order: distance($to) = $dist1"

		    # Updating here might be a bit slower then after the loop
		    # (some duplicate updates possible), but is very convenient...
		    db_dml update_distance "
			update wf_transitions
			set sort_order = :dist1
			where
				workflow_key = :workflow_key
				and transition_key = :to
		    "

		    # Append the new to-node to the end of the active nodes.
		    lappend active_nodes $to
		}
	    }
	}
    }
}




# ----------------------------------------------------------------------
# Adapters to show WF components
# ---------------------------------------------------------------------

ad_proc -public im_workflow_graph_component {
    -object_id:required
} {
    Show a Graphical WF representation of a workflow associated
    with an object.
} {
    set user_id [ad_get_user_id]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set subsite_id [ad_conn subsite_id]
    set reassign_p [permission::permission_p -party_id $user_id -object_id $subsite_id -privilege "wf_reassign_tasks"]
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set date_format "YYYY-MM-DD"
    set project_id $object_id
    set return_url [im_url_with_query]

    # ---------------------------------------------------------------------
    # Check if there is a WF case with object_id as reference object
    set cases [db_list case "select case_id from wf_cases where object_id = :object_id"]

    set graph_html ""
    switch [llength $cases] {
	0 {
	    # No case found - just return an empty string, 
	    # so that the component disappears
	    return ""
	}
	1 {
	    # Exactly one case found (default situation).
	    # Return the WF graph component
	    set size [parameter::get_from_package_key -package_key "intranet-workflow" -parameter "WorkflowComponentWFGraphSize" -default "5,5"]
	    set case_id [lindex $cases 0]
	    set params [list [list case_id $case_id] [list size $size]]
	    set graph_html [ad_parse_template -params $params "/packages/acs-workflow/www/case-state-graph"]
	}
	default {
	    # More then one WF for this object.
	    # This is possible in terms of the WF structure,
	    # but not desired here.
	    return ""
	}
    }

    # ---------------------------------------------------------------------
    # Who has been acting on the WF until now?
    set history_html ""
    set history_sql "
	select	t.*,
		tr.transition_name,
		to_char(t.started_date, :date_format) as started_date_pretty,
		to_char(t.finished_date, :date_format) as finished_date_pretty,
		im_name_from_user_id(t.holding_user) as holding_user_name
	from
		wf_transitions tr, 
		wf_tasks t
	where
		t.case_id = :case_id
		and t.state not in ('enabled', 'started')
		and tr.workflow_key = t.workflow_key
		and tr.transition_key = t.transition_key
		and trigger_type = 'user'
	order by t.enabled_date
    "
    set cnt 0
    db_foreach history $history_sql {
	append history_html "
	    <tr $bgcolor([expr $cnt % 2])>
		<td>$transition_name</td>
		<td><nobr><a href=/intranet/users/view?user_id=$holding_user>$holding_user_name</a></nobr></td>
		<td><nobr>$started_date_pretty</nobr></td>
	    </tr>
	"
        incr cnt
    }

    set history_html "
		<table class=\"table_list_page\">
		<tr class=rowtitle>
		  <td colspan=3 align=center class=rowtitle>[lang::message::lookup "" intranet-workflow.Past_actions "Past Actions"]</td>
		</tr>
		<tr class=rowtitle>
			<td class=rowtitle>[lang::message::lookup "" intranet-workflow.What "What"]</td>
			<td class=rowtitle>[lang::message::lookup "" intranet-workflow.Who "Who"]</td>
			<td class=rowtitle>[lang::message::lookup "" intranet-workflow.When "When"]</td>
		</tr>
		$history_html
		</table>
    "


    # ---------------------------------------------------------------------
    # Next Transition Information
    set transition_html ""
    set transition_sql "
	select	t.*,
		tr.*,
		to_char(t.started_date, :date_format) as started_date_pretty,
		to_char(t.finished_date, :date_format) as finished_date_pretty,
		im_name_from_user_id(t.holding_user) as holding_user_name,
		to_char(t.trigger_time, :date_format) as trigger_time_pretty
	from
		wf_transitions tr, 
		wf_tasks t
	where
		t.case_id = :case_id
		and t.state in ('enabled', 'started')
		and tr.workflow_key = t.workflow_key
		and tr.transition_key = t.transition_key
	order by t.enabled_date
    "
    set cnt 0
    db_foreach transition $transition_sql {
	append transition_html "<table class=\"table_list_page\">\n"
	append transition_html "<tr class=rowtitle><td colspan=2 class=rowtitle align=center>
		[lang::message::lookup "" intranet-workflow.Next_step_details "Next Step: Details"]
	</td></tr>\n"
	append transition_html "<tr $bgcolor([expr $cnt % 2])><td>
		[lang::message::lookup "" intranet-workflow.Task_name "Task Name"]
	</td><td>$transition_name</td></tr>\n"
        incr cnt
	append transition_html "<tr $bgcolor([expr $cnt % 2])><td>
		[lang::message::lookup "" intranet-workflow.Holding_user "Holding User"]
	</td><td>$holding_user_name</td></tr>\n"
        incr cnt
	append transition_html "<tr $bgcolor([expr $cnt % 2])><td>
		[lang::message::lookup "" intranet-workflow.Task_state "Task State"]
	</td><td>$state</td></tr>\n"
        incr cnt
	append transition_html "<tr $bgcolor([expr $cnt % 2])><td>
		[lang::message::lookup "" intranet-workflow.Automatic_trigger "Automatic Trigger"]
	</td><td>$trigger_time_pretty</td></tr>\n"
        incr cnt

	if {$reassign_p} {
	    append transition_html "
		<tr class=rowplain><td colspan=2>
		<li><a href=[export_vars -base "/[im_workflow_url]/assign-yourself" {task_id return_url}]>[lang::message::lookup "" intranet-workflow.Assign_yourself "Assign yourself"]</a>
		<li><a href=[export_vars -base "/[im_workflow_url]/task-assignees" {task_id return_url}]>[lang::message::lookup "" intranet-workflow.Assign_somebody_else "Assign somebody else"]</a>
		</td></tr>
            "
	}

	append transition_html "</table>\n"
    }

    # ---------------------------------------------------------------------
    # Who is assigned to the current transition?
    set assignee_html ""
    set assignee_sql "
	select	t.*,
		t.holding_user,
		tr.transition_name,
		ta.party_id,
		acs_object__name(ta.party_id) as party_name,
		im_name_from_user_id(ta.party_id) as user_name,
		o.object_type as party_type
	from
		wf_transitions tr, 
		wf_tasks t,
		wf_task_assignments ta,
		acs_objects o
	where
		t.case_id = :case_id
		and t.state in ('enabled', 'started')
		and tr.workflow_key = t.workflow_key
		and tr.transition_key = t.transition_key
		and ta.task_id = t.task_id
		and ta.party_id = o.object_id
	order by t.enabled_date
    "
    set cnt 0
    db_foreach assignee $assignee_sql {
	if {"user" == $party_type} { set party_name $user_name } 
	if {$holding_user == $party_id} { set party_name "<b>$party_name</b>" }
	set party_link "<a href=/intranet/users/view?user_id=$party_id>$party_name</a>"
	if {"user" != $party_type} { set party_link $party_name	}
	append assignee_html "
	    <tr $bgcolor([expr $cnt % 2])>
		<td>$transition_name</td>
		<td><nobr>$party_link</nobr></td>
	    </tr>
	"
        incr cnt
    }
    if {0 == $cnt} {
	append assignee_html "
	    <tr $bgcolor([expr $cnt % 2])>
		<td colspan=2><i>&nbsp;Nobody assigned</i></td>
	    </tr>
        "
    }

    set assignee_html "
		<table class=\"table_list_page\">
		<tr class=rowtitle>
		  <td colspan=2 align=center class=rowtitle
		  >[lang::message::lookup "" intranet-workflow.Currrent_assignees "Current Assignees"]</td>
		</tr>
		<tr class=rowtitle>
			<td class=rowtitle>[lang::message::lookup "" intranet-workflow.What "What"]</td>
			<td class=rowtitle>[lang::message::lookup "" intranet-workflow.Who "Who"]</td>
		</tr>
		$assignee_html
    "

    if {$reassign_p} {
        append assignee_html "
		<tr class=rowplain><td colspan=2>
		<li><a href='[export_vars -base "/[im_workflow_url]/case?" {case_id}]'>[_ intranet-workflow.Debug_Case]</a>
		<li><a href='[export_vars -base "/intranet-workflow/reset-case?" {return_url project_id {place_key "start"} {action_pretty "restart"}}]'>[_ intranet-workflow.Reset_Case]</a>
		</td></tr>
        "
    }

    append assignee_html "</table>\n"

    return "
	<table>
	<tr valign=top>
	<td>$graph_html</td>
	<td>
		$history_html<br>
		$transition_html<br>
		$assignee_html
	</td>
	</tr>
	</table>
    "
}


ad_proc -public im_workflow_action_component {
    -object_id:required
} {
    Shows WF default actions for the specified object, 
    or a user-defined action panel if configured in the WF.<p>

    There are 5 different cases to deal with:
	- Enable: The user needs to press the "Start" button to
	  take ownership of that task.
		a: The current user is in the assignee list
		b: The current user is not assigned to the task
	- Started: The task has been started:
		a: This is the user who started the case
		b: This is not the user who started the case
	- Canceled
	- Finished
} {
    set current_user_id [ad_get_user_id]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set return_url [im_url_with_query]

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "

    # Get all "enabled" task for this object:
    set enabled_tasks [db_list enabled_tasks "
		select
			wft.task_id
		from    wf_tasks wft,
			wf_cases wfc
		where
			wfc.object_id = :object_id
			and wfc.case_id = wft.case_id
			and wft.state in ('enabled', 'started')
    "]

    set result ""
    set graph_html ""

    template::multirow create panels header template_url bgcolor
    foreach task_id $enabled_tasks {

	# Clean the array for the next task
	array unset task

	set export_form_vars [export_vars -form {task_id return_url}]

	# ---------------------------------------------------------
	# Get everything about the task

	if {[catch {
	    array set task [wf_task_info $task_id]
	} err_msg]} {
	    ad_return_complaint 1 "<li><b>[lang::message::lookup "" acs-workflow.Task_not_found "Task not found:"]</b><p>
	        [lang::message::lookup "" acs-workflow.Task_not_found_message "
                This error can occur if a system administrator has deleted a workflow.<br>
                This situation should not occur during normal operations.<p>
                Please contact your System Administrator"]
            "
	    return
	}

	set task(add_assignee_url) "/[im_workflow_url]/assignee-add?[export_url_vars task_id]"
	set task(assign_yourself_url) "/[im_workflow_url]/assign-yourself?[export_vars -url {task_id return_url}]"
	set task(manage_assignments_url) "/[im_workflow_url]/task-assignees?[export_vars -url {task_id return_url}]"
	set task(cancel_url) "/[im_workflow_url]/task?[export_vars -url {task_id return_url {action.cancel Cancel}}]"
	set task(action_url) "/[im_workflow_url]/task"
	set task(return_url) $return_url

	set context [list [list "/[im_workflow_url]/case?case_id=$task(case_id)" "$task(object_name) case"] "$task(task_name)"]
	set panel_color "#dddddd"
	set show_action_panel_p 1

	# ---------------------------------------------------------
	# Graph component
	set size [parameter::get_from_package_key -package_key "intranet-workflow" -parameter "ActionComponentWFGraphSize" -default "3,3"]
	set params [list [list case_id $task(case_id)] [list size $size]]
	set graph_html [ad_parse_template -params $params "/packages/acs-workflow/www/case-state-graph"]

	# ---------------------------------------------------------
	# Get action panel(s) for the task

	set override_action 0
	set this_user_is_assigned_p 1
	set action_panels_sql "
		select
			tp.header, 
			tp.template_url
		from
			wf_context_task_panels tp, 
			wf_cases c,
			wf_tasks t
		where
			t.task_id = :task_id
			and c.case_id = t.case_id
			and tp.context_key = c.context_key
			and tp.workflow_key = c.workflow_key
			and tp.transition_key = t.transition_key
			and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and :this_user_is_assigned_p = 1))
			and tp.overrides_action_p = 't'
		order by tp.sort_order
        "
	set action_panel_count [db_string action_panel_count "select count(*) from ($action_panels_sql) t"]
	if {0 == $action_panel_count} {
	    set action_panels_sql "
		select	'Action' as header,
			'task-action' as template_url
	    "
	}

	set ctr 0
	db_foreach action_panels $action_panels_sql {

	    set task_actions {}

	    # --------------------------------------------------------------------
	    # Table header common to all states
	    append result "
				<form action='/[im_workflow_url]/task' method='post'>
				$export_form_vars
				<table>
		        	<tr $bgcolor([expr $ctr%2])>
		        	    <td>Task Name</td>
		        	    <td>$task(task_name)</td>
		        	</tr>
	    "
	    incr ctr

	    if {"" != [string trim $task(instructions)]} {
		append result "
		        	<tr $bgcolor([expr $ctr%2])>
		        	    <td>Task Description</td>
		        	    <td>$task(instructions)</td>
		        	</tr>
		"
		incr ctr
	    }

	    if {$user_is_admin_p} {
		append result "
		        	<tr $bgcolor([expr ($ctr+1)%2])>
		        	    <td>Task Status</td>
		        	    <td>$task(state)</td>
		        	</tr>
	        "
		incr ctr
	    }

	    switch $task(state) {

		enabled {
		    # --------------------------------------------------------------------
		    if {$task(this_user_is_assigned_p)} {
			append result "
				<tr class=rowodd>
					<td>Action</th>
					<td><input type='submit' name='action.start' value='Start task' /></td>
				</tr>
			"
		    } else {
			append result "
				<tr $bgcolor([expr $ctr%2])>
					<td>Action</td>
					<td>
					    This task has been assigned to somebody else.<br>
					    There is nothing to do for you right now.
					</td>
				</tr>				
			"
			incr ctr
		    }
		}


		started {
		    # --------------------------------------------------------------------

		    lappend task_actions "(<a href='$task(cancel_url)'>cancel task</a>)"

		    if {$task(this_user_is_assigned_p)} { 

			template::multirow foreach task_roles_to_assign {
			    append result "
		                <tr class=roweven>
		                    <td>Assign $role_name</td>
		                    <td>$assignment_widget</td>
		                </tr>
			    "
			}

			template::multirow foreach task_attributes_to_set {
			    append result "
		                <tr class=rowodd>
		                    <td>$pretty_name</td>
		                    <td>$attribute_widget</td>
		                </tr>
			    "
			}
			append result "
		             <tr class=rowodd>
		                 <td>Comment</td>
		                 <td><textarea name='msg' cols=20 rows=4></textarea></td>
		             </tr>
		             <tr class=roweven>
		                 <td>Action</td>
		                 <td>
		                     <input type='submit' name='action.finish' value='Task done' />
		                 </td>
		             </tr>
			"

			append result "
				<tr class=roweven>
					<td>Started</td>
					<td>$task(started_date_pretty)&nbsp; &nbsp; </td>
				</tr>
			"

		    } else {

			append result "
				    <tr><td>Held by</td><td><a href='/intranet/users/view?user_id=$task(holding_user)'>$task(holding_user_name)</a></td></tr>
				    <tr><td>Since</td><td>$task(started_date_pretty)</td></tr>
				    <tr><td>Timeout</td><td>$task(hold_timeout_pretty)</td></tr>
			"

		    }
		    
		}

		canceled {
		    if {$task(this_user_is_assigned_p)} { 
append result "You canceled this task on $task(canceled_date_pretty).<p><a href='$return_url'>Go back</a>" 
		    } else {
append result "This task has been canceled by <a href='/intranet/users/view?user_id=$task(holding_user)'>$task(holding_user_name)</a> on $task(canceled_date_pretty)"
		    }
		    
		}
		finished {
		    if {$task(this_user_is_assigned_p)} { 
append result "You finished this task on $task(finished_date_pretty).<p><a href='$return_url'>Go back</a>"
		    } else {
append result "This task was completed by <a href='/shared/community-member?user_id=$task(holding_user)'>$task(holding_user_name)</a>at $task(finished_date_pretty)"

		    }
		    
		}
	
		default {
		    append result "<p><font=red>Found task with invalid state '$task(state)'</font></p>"
		}
	
	    }
	    # end of switch


	    # --------------------------------------------------------------------
	    # Timeout
	    if {"" != $task(hold_timeout_pretty)} {
		set timeout_html "<td>Timeout</td><td>$task(hold_timeout_pretty)</td>\n"
		append result "
				<tr $bgcolor([expr $ctr%2])>
					$timeout_html
				</tr>
		"
		incr ctr
	    }

	    # --------------------------------------------------------------------
	    # Deadline
	    if {"" != [string trim $task(deadline_pretty)]} {
		if {$task(days_till_deadline) < 1} {
		    set deadline_html "<td>Deadline</td><td><font color='red'><strong>Deadline is $task(deadline_pretty)</strong></font></td>\n"
		} else {
		    set deadline_html "<td>Deadline</td><td>Deadline is $task(deadline_pretty)</td>\n"
		}
		append result "
				<tr $bgcolor([expr $ctr%2])>
					$deadline_html
				</tr>
		"
		incr ctr
	    }

	    # --------------------------------------------------------------------
	    # Assigned users
	    set assigned_users {}
	    if {[im_permission $current_user_id "wf_reassign_tasks"]} {
		template::multirow foreach task_assigned_users { 
		    set user_url [export_vars -base "/intranet/users/view" {user_id}]
		    lappend assigned_users "<a href='$user_url'><nobr>$name</nobr></a>\n"
		}
	    }
	    if {[llength $assigned_users] > 0} {
		append result "
				<tr $bgcolor([expr $ctr%2])>
					<td>Assigned Users</td>
					<td>[join $assigned_users "<br>\n"]</td>
				</tr>
		"
		incr ctr
	    }

	    # --------------------------------------------------------------------
	    # Extreme Actions
	    if {[im_permission $current_user_id "wf_reassign_tasks"]} {
		if {!$task(this_user_is_assigned_p)} {
		    lappend task_actions "(<a href='$task(assign_yourself_url)'>assign yourself</a>)"
		}
		lappend task_actions "(<a href='$task(manage_assignments_url)'>reassign task</a>)"
	    }

	    if {[llength $task_actions] > 0} {
		append result "
				<tr $bgcolor([expr $ctr%2])>
					<td>Extreme Actions</td>
					<td>[join $task_actions "&nbsp; \n"]</td>
				</tr>
		"
		incr ctr
	    }

	    # --------------------------------------------------------------------
	    # Close the table
	    append result "
			</table>
			</form>
	    "
	    
	}
    }
    if {"" == $result} {
	return "
		<table class=\"table_list_page\">
		<tr valign=top>
		<td>
			<b>[lang::message::lookup "" intranet-helpdesk.Workflow_Finished "Workflow Finished"]</b><br>
			[lang::message::lookup "" intranet-helpdesk.Workflow_Finished_msg "
				The workflow has finished and there are no more actions to take.
			"]
		</td>
		<td>$graph_html</td>
		</tr>
		</table>
	"
    }

    return "
	<table width='100%' >
	<tr valign=top>
	<td>$result</td>
	<td>$graph_html</td>
	</tr>
	</table>
    "
}


ad_proc -public im_workflow_journal_component {
    -object_id:required
} {
    Show the WF Journal for an object
} {
    # Check if there is a WF case with object_id as reference object
    set cases [db_list case "select case_id from wf_cases where object_id = :object_id"]
    if {[llength $cases] != 1} { return "" }

    set params [list [list case_id [lindex $cases 0]]]
    set result [ad_parse_template -params $params "/packages/acs-workflow/www/journal"]
    return $result
}


ad_proc -public im_workflow_new_journal {
    -case_id:required
    -action:required
    -action_pretty:required
    -message:required
} {
    Creates a new journal entry that can be passed to PL/SQL routines
} {
    set user_id [ad_get_user_id]
    set peer_ip [ad_conn peeraddr]

    set jid [db_string new_journal "
	select journal_entry__new (
		null,
		:case_id,
		:action,
		:action_pretty,
		now(),
		:user_id,
		:peer_ip,
		:message
	)
    "]
    return $jid
}



ad_proc -public im_workflow_task_action {
    -task_id:required
    -action:required
    -message:required
} {
    Similar to wf_task_action, but without checking if the current_user_id
    is the holding user. This allows for reassigning tasks even if the task
    was started.
} {
    set user_id [ad_get_user_id]
    set peer_ip [ad_conn peeraddr]
    set case_id [db_string case "select case_id from wf_tasks where task_id = :task_id" -default 0]
    set action_pretty [lang::message::lookup "" intranet-workflow.Action_$action $action]

    set journal_id [im_workflow_new_journal \
	-case_id $case_id \
	-action $action \
	-action_pretty $action_pretty \
	-message $message \
    ]

    db_string cancel_action "select workflow_case__end_task_action (:journal_id, :action, :task_id)"

    return $journal_id
}



# ----------------------------------------------------------------------
# Inbox for "Business Objects"
# ----------------------------------------------------------------------

ad_proc -public im_workflow_home_inbox_component {
    {-view_name "workflow_home_inbox" }
    {-order_by_clause ""}
    {-relationship "assignment_group" }
    {-relationships {holding_user assignment_group none} }
    {-object_type ""}
    {-subtype_id ""}
    {-status_id ""}
} {
    Returns a HTML table with the list of workflow tasks for the
    current user.
    Assumes that all shown objects are ]po[ "Business Objects", so 
    we can show sub-type and status of the objects.
    @param show_relationships Determines which relationships to show.
	   Showing more general relationship implies showing more
	   specific ones:<ul>
	   <li>holding_user:	The current iser has started the WF task. 
				Nobody else can execute the task, unless an 
				admin "steals" the task.
	   <li>my_object:	The current user initially created the 
				underlying object. So he can follow-up on
				the status of his expenses, vacations etc.
	   <li>specific_assignment: User has specifically been assigned
				to be the one to execute the task
	   <li>assignment_group:User belongs to the group of users 
				assigned to the task.
	   <li>vacation_group:	User belongs to the vacation replacements
	   <li>object_owner:	Users owns the underyling biz object.
	   <li>object_write:	User has the right to modify the
				underlying business object.
	   <li>object_read:	User has the right to read the 
				underlying business object.
	   <li>none:		The user has no relationship at all
				with the task to complete.
    @paramm relationship Determines a single relationship 
} {
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "

    set sql_date_format "YYYY-MM-DD"
    set current_user_id [ad_get_user_id]
    set return_url [im_url_with_query]
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }

    # Order_by logic: Get form HTTP session or use default
    if {"" == $order_by_clause} {
	set order_by [ns_set get $form_vars "wf_inbox_order_by"]
	set order_by_clause [db_string order_by "
		select	order_by_clause
		from	im_view_columns
		where	view_id = :view_id and
			column_name = :order_by
	" -default ""]
    }

    # Calculate the current_url without "wf_inbox_order_by" variable
    set current_url "[ns_conn url]?"
    ns_set delkey $form_vars wf_inbox_order_by
    set form_vars_size [ns_set size $form_vars]
    for { set i 0 } { $i < $form_vars_size } { incr i } {
	set key [ns_set key $form_vars $i]
	if {"" == $key} { continue }

	# Security check for cross site scripting
        if {![regexp {^[a-zA-Z0-9_\-]*$} $key]} {
            im_security_alert \
		-location im_workflow_home_inbox_component \
                -message "Invalid URL var characters" \
                -value [ns_quotehtml $key]
            # Quote the harmful keys
            regsub -all {[^a-zA-Z0-9_\-]} $key "_" key
        }

	set value [ns_set get $form_vars $key]
	append current_url "$key=[ns_urlencode $value]"
	ns_log Notice "im_workflow_home_inbox_component: i=$i, key=$key, value=$value"
	if { $i < [expr $form_vars_size-1] } { append url_vars "&" }
    }

    if {"" == $order_by_clause} {
	set order_by_clause [parameter::get_from_package_key -package_key "intranet-workflow" -parameter "HomeInboxOrderByClause" -default "creation_date"]
    }

    # Let Admins see everything
    if {[im_is_user_site_wide_or_intranet_admin $current_user_id]} { set relationship "none" }

    # Set relationships based on a single variable
    case $relationship {
	holding_user { set relationships {my_object holding_user}}
	my_object { set relationships {my_object holding_user}}
	specific_assignment { set relationships {my_object holding_user specific_assigment}}
	assignment_group { set relationships {my_object holding_user specific_assigment assignment_group}}
	object_owner { set relationships {my_object holding_user specific_assigment assignment_group object_owner}}
	object_write { set relationships {my_object holding_user specific_assigment assignment_group object_owner object_write}}
	object_read { set relationships {my_object holding_user specific_assigment assignment_group object_owner object_write object_read}}
	none { set relationships {my_object holding_user specific_assigment assignment_group object_owner object_write object_read none}}
    }

    # ---------------------------------------------------------------
    # Columns to show
  
    set column_sql "
	select	column_id,
		column_name,
		column_render_tcl,
		visible_for,
		(order_by_clause is not null) as order_by_clause_exists_p
	from	im_view_columns
	where	view_id = :view_id
	order by sort_order, column_id
    "

    set column_vars [list]
    set colspan 1
    set table_header_html "<tr class=\"list-header\">\n"

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_vars "$column_render_tcl"
	    regsub -all " " $column_name "_" col_txt
	    set col_txt [lang::message::lookup "" intranet-workflow.$col_txt $column_name]
	    set col_url [export_vars -base $current_url {{wf_inbox_order_by $column_name}}]
	    set admin_link "<a href=[export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}] target=\"_blank\">[im_gif wrench]</a>"
	    if {!$user_is_admin_p} { set admin_link "" }
	    if {"f" == $order_by_clause_exists_p} {
		append table_header_html "<th class=\"list\">$col_txt$admin_link</td>\n"
	    } else {
		append table_header_html "<th class=\"list\"><a href=\"$col_url\">$col_txt</a>$admin_link</td>\n"
	    }
	    incr colspan
	}
    }

    append table_header_html "</tr>\n"


    # ---------------------------------------------------------------
    # SQL Query

    # Get the list of all "open" (=enabled or started) tasks with their assigned users
    set tasks_sql "
	select
		ot.pretty_name as object_type_pretty,
		o.object_id,
		o.creation_user as owner_id,
		o.creation_date,
		im_name_from_user_id(o.creation_user) as owner_name,
		acs_object__name(o.object_id) as object_name,
		im_biz_object__get_type_id(o.object_id) as type_id,
		im_biz_object__get_status_id(o.object_id) as status_id,
		tr.transition_name,
		t.holding_user,
		t.task_id,
		im_workflow_task_assignee_names(t.task_id) as assignees_pretty
	from
		acs_object_types ot,
		acs_objects o,
		wf_cases ca,
		wf_transitions tr,
		wf_tasks t
	where
		ot.object_type = o.object_type
		and o.object_id = ca.object_id
		and ca.case_id = t.case_id
		and t.state in ('enabled', 'started')
		and t.transition_key = tr.transition_key
		and t.workflow_key = tr.workflow_key
    "

    if {"" != $order_by_clause} {
	append tasks_sql "\torder by $order_by_clause"
    }

    # ---------------------------------------------------------------
    # Store the conf_object_id -> assigned_user relationship in a Hash array
    set tasks_assignment_sql "
    	select
		t.*,
		m.member_id as assigned_user_id
	from
		($tasks_sql) t
		LEFT OUTER JOIN (
			select distinct
				m.member_id,
				ta.task_id
			from	wf_task_assignments ta,
				party_approved_member_map m
			where	m.party_id = ta.party_id
		) m ON t.task_id = m.task_id
    "
    db_foreach assigs $tasks_assignment_sql {
	set assigs ""
    	if {[info exists assignment_hash($object_id)]} { set assigs $assignment_hash($object_id) }
	lappend assigs $assigned_user_id
	set assignment_hash($object_id) $assigs
    }

    # ---------------------------------------------------------------
    # Format the Result Data

    set ctr 0
    set table_body_html ""
    db_foreach tasks $tasks_sql {

	set assigned_users ""
	set assignees_pretty [im_workflow_replace_translations_in_string $assignees_pretty]
	set assignee_pretty $assignees_pretty

    	if {[info exists assignment_hash($object_id)]} { set assigned_users $assignment_hash($object_id) }

	# Determine the type of relationship to the object - why is the task listed here?
	# The problem: There may be more then one relationship, so we need to pull out the
	# most relevant one. Maybe reorganize the code later to enable all rels as a bitmap
	# and the all of the rels in the inbox...
	set rel "none"
	if {$current_user_id == $owner_id} { set rel "my_object" }
	foreach assigned_user_id $assigned_users {
	    if {$current_user_id == $assigned_user_id && $rel != "holding_user"} { 
		set rel "assignment_group" 
	    }
	    if {$current_user_id == $holding_user} { 
		set rel "holding_user" 
	    }
	}

	if {[lsearch $relationships $rel] == -1} { continue }

	# L10ned version of next action
	regsub -all " " $transition_name "_" next_action_key
	set next_action_l10n [lang::message::lookup "" intranet-workflow.$next_action_key $transition_name]
	set object_subtype [im_category_from_id $type_id]
	set status [im_category_from_id $status_id]
	set object_url "[im_biz_object_url $object_id "view"]&return_url=[ns_urlencode $return_url]"
	set owner_url [export_vars -base "/intranet/users/view" {return_url {user_id $owner_id}}]
	
	set action_url [export_vars -base "/[im_workflow_url]/task" {return_url task_id}]
	set action_link "<a href=$action_url>$next_action_l10n</a>"

	# Don't show the "Action" link if the object is mine...
	if {"my_object" == $rel} {
	    set action_link $next_action_l10n
	} 

	set action_link "asdf"

	# L10ned version of the relationship of the user to the object
	set relationship_l10n [lang::message::lookup "" intranet-workflow.$rel $rel]

	set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td valign=top>"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
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

    # ---------------------------------------------------------------
    # Return results
    
    set admin_action_options ""
    if {$user_is_admin_p} {
	set admin_action_options "<option value=\"nuke\">[lang::message::lookup "" intranet-workflow.Nuke_Object "Nuke Object (Admin only)"]</option>"
    }

    set table_action_html "
	<tr class=rowplain>
	<td colspan=99 class=rowplain align=right>
	    <select name=\"operation\">
	    <option value=\"delete_membership\">[lang::message::lookup "" intranet-workflow.Remove_From_Inbox "Remove from Inbox"]</option>
	    $admin_action_options
	    </select>
	    <input type=submit name=submit value='[lang::message::lookup "" intranet-workflow.Submit "Submit"]'>
	</td>
	</tr>
    "
    set enable_bulk_action_p [parameter::get_from_package_key -package_key "intranet-workflow" -parameter "EnableWorkflowInboxBulkActionsP" -default 0]
    if {!$enable_bulk_action_p} { set table_action_html "" }

    set return_url [ad_conn url]?[ad_conn query]
    return "
	<form action=\"/intranet-workflow/inbox-action\" method=POST>
	[export_form_vars return_url]
	<table class=\"table_list_page\">
	  $table_header_html
	  $table_body_html
	  $table_action_html
	</table>
	</form>
    "
}


# ---------------------------------------------------------------
# Skip the first tasks of the workflow.
# This is useful for the very first transition of an approval WF

ad_proc -public im_workflow_skip_first_transition {
    -case_id:required
} {
    Skip the first tasks of the workflow.
    This is useful for the very first transition of an approval WF
    There can be potentially more then one of such tasks..
} {
    set user_id [ad_get_user_id]

    # Get the first "enabled" task of the new case_id:
    set enabled_tasks [db_list enabled_tasks "
		select	task_id
		from	wf_tasks
		where	case_id = :case_id
			and state = 'enabled'
    "]

    foreach task_id $enabled_tasks {
	# Assign the first task to the user himself and start the task
	set wf_case_assig [db_string wf_assig "select workflow_case__add_task_assignment (:task_id, :user_id, 'f')"]

	# Start the task. Saves the user the work to press the "Start Task" button.
	set journal_id [db_string wf_action "select workflow_case__begin_task_action (:task_id,'start','[ad_conn peeraddr]',:user_id,'')"]
	set journal_id2 [db_string wf_start "select workflow_case__start_task (:task_id,:user_id,:journal_id)"]
	# Finish the task. That forwards the token to the next transition.
	set journal_id3 [db_string wf_finish "select workflow_case__finish_task(:task_id, :journal_id)"]
    }
}



# ----------------------------------------------------------------------
# Workflow Permissions
#
# Check permissions represented as a list of letters {r w d a}
# per business object based on role, object type and object status.
#
# There is a default logic:
# 	1. (role, status, type) is checked.
# 	2. (role, type) is checked.
#	3. (role, status) is checked.
#	4. (role) is checked.
#
# 2.) and 3.) are OK, because type and status are disjoint.
# ----------------------------------------------------------------------

ad_proc im_workflow_object_permissions {
    -object_id:required
    -perm_table:required
} {
    Determines whether a user can execute the specified
    "perm_letter" (i.e. r=read, w=write, d=delete) operation
    on the object.
    Returns the list of permissions.
} {
    # stuff permission from table into hash
    array set perm_hash $perm_table

    # ------------------------------------------------------
    # Pull out the relevant variables
    set user_id [ad_get_user_id]
    set owner_id [db_string owner "select creation_user from acs_objects where object_id = $object_id" -default 0]
    if {"" == $owner_id} { set owner_id 0 }
    set status_id [db_string status "select im_biz_object__get_status_id (:object_id)" -default 0]
    set type_id [db_string status "select im_biz_object__get_type_id (:object_id)" -default 0]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_hr_p [im_user_is_hr_p $user_id]
    set user_is_accounting_p [im_user_is_accounting_p $user_id]
    set user_is_owner_p [expr $owner_id == $user_id]
    set user_is_assignee_p [db_string assignee_p "
	select	count(*)
	from	(select	pamm.member_id
		from	wf_cases wfc,
			wf_tasks wft,
			wf_task_assignments wfta,
			party_approved_member_map pamm
		where	wfc.object_id = :object_id
			and wft.case_id = wfc.case_id
			and wft.state in ('enabled', 'started')
			and wft.task_id = wfta.task_id
			and wfta.party_id = pamm.party_id
			and pamm.party_id = :user_id
		) t
    "]
    
    ns_log Notice "im_workflow_object_permissions: status_id=$status_id, user_id=$user_id, owner_id=$owner_id"
    ns_log Notice "im_workflow_object_permissions: user_is_owner_p=$user_is_owner_p, user_is_assignee_p=$user_is_assignee_p, user_is_hr_p=$user_is_hr_p, user_is_admin_p=$user_is_admin_p"
    ns_log Notice "im_workflow_object_permissions: hash=[array get perm_hash]"

    if {0 == $status_id} {
	ad_return_complaint 1 "<b>Invalid Configuration</b>:<br>The PL/SQL function 'im_biz_object__get_status_id (:object_id)' has returned an invalid status_id for object #$object_id.  "
    }

    # ------------------------------------------------------
    # Calculate permissions
    set perm_set {}

    if {$user_is_owner_p} { 
	set perm_letters {}
	if {[info exists perm_hash(owner-$status_id)]} { set perm_letters $perm_hash(owner-$status_id)}
	set perm_set [set_union $perm_set $perm_letters]
    }
 
    if {$user_is_assignee_p} { 
	set perm_letters {}
	if {[info exists perm_hash(assignee-$status_id)]} { set perm_letters $perm_hash(assignee-$status_id)}
	set perm_set [set_union $perm_set $perm_letters]
    }

    if {$user_is_hr_p} { 
	set perm_letters {}
	if {[info exists perm_hash(hr-$status_id)]} { set perm_letters $perm_hash(hr-$status_id)}
	set perm_set [set_union $perm_set $perm_letters]
    }

    if {$user_is_accounting_p} { 
	set perm_letters {}
	if {[info exists perm_hash(accounting-$status_id)]} { set perm_letters $perm_hash(accounting-$status_id)}
	set perm_set [set_union $perm_set $perm_letters]
    }

    # Admins can do everything anytime.
    if {$user_is_admin_p} { set perm_p {v r w d a } }

    return $perm_set
}





# ---------------------------------------------------------------
# Cancel the workflow in case the underlying object gets closed, 
# such like a ticket of a deleted project.
#

ad_proc im_workflow_cancel_workflow {
    -object_id:required
} {
    Cancel the workflow in case the underlying object gets closed, 
    such like a ticket of a deleted project.
} {
    set journal_id ""
    
    # Delete all tokens of the case
    db_dml delete_tokens "
    	delete from wf_tokens
    	where case_id in (select case_id from wf_cases where object_id = :object_id) and
    	state in ('free', 'locked')
    "
    
    set cancel_tasks_sql "
    	select 	task_id as wf_task_id
    	from	wf_tasks
    	where	case_id in (select case_id from wf_cases where object_id = :object_id) and
		state in ('started')
    "
    db_foreach cancel_started_tasks $cancel_tasks_sql {
        ns_log Notice "im_workflow_cancel_workflow: canceling task $wf_task_id"
        set journal_id [im_workflow_task_action -task_id $wf_task_id -action "cancel" -message "Canceling workflow"]
    }

    # fraber 101112: 
    # ToDo: Validate that it's OK just to change the status of a task to "canceled"
    # in order to disable it. Or should the task be deleted?
    #
    set del_enabled_tasks_sql "
    	select 	task_id as wf_task_id
    	from	wf_tasks
    	where	case_id in (select case_id from wf_cases where object_id = :object_id) and
		state in ('enabled')
    "
    db_foreach cancel_started_tasks $del_enabled_tasks_sql {
        ns_log Notice "im_workflow_cancel_workflow: deleting enabled task $wf_task_id"
	db_dml del_task "update wf_tasks set state = 'canceled' where task_id = :wf_task_id"
    }
}

