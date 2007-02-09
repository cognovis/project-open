# /packages/intranet-workflow/tcl/intranet-workflow-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
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


# ----------------------------------------------------------------------
# Selects & Options
# ---------------------------------------------------------------------

ad_proc -public im_workflow_list_options {
    {-include_empty 0}
    {-min_case_count 0}
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

    set package_url "/workflow/"

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
<table cellspacing=1 cellpadding=0>
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
    set return_url [ad_conn url]?[export_url_vars project_id]

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
	    set size "5,5"
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
		<td><nobr>$transition_name</nobr></td>
		<td><nobr><a href=/intranet/users/view?user_id=$holding_user>$holding_user_name</a></nobr></td>
		<td><nobr>$started_date_pretty</nobr></td>
	    </tr>
	"
        incr cnt
    }

    set history_html "
		<table>
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
	append transition_html "<table>\n"
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
		<li><a href=[export_vars -base "/workflow/assign-yourself" {task_id return_url}]>[lang::message::lookup "" intranet-workflow.Assign_yourself "Assign yourself"]</a>
		<li><a href=[export_vars -base "/workflow/task-assignees" {task_id return_url}]>[lang::message::lookup "" intranet-workflow.Assign_somebody_else "Assign somebody else"]</a>
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
		<td><nobr>$transition_name</nobr></td>
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
		<table>
		<tr class=rowtitle>
		  <td colspan=2 align=center class=rowtitle>[lang::message::lookup "" intranet-workflow.Currrent_assignees "Current Assignees"]</td>
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
		<li><a href='[export_vars -base "/workflow/case?" {case_id}]'>Debug Case</a>
		<li><a href='[export_vars -base "/intranet-workflow/reset-case?" {return_url project_id {place_key "start"} {action_pretty "restart"}}]'>Reset Case</a>
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