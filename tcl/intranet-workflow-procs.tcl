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
    set own_tasks "<h3>[lang::message::lookup "" intranet-workflow.All_Tasks "Your Tasks"]</h3>\n$own_tasks"

    set all_tasks [template::adp_parse $template_path [list package_url $package_url]]
    set all_tasks "<h3>[lang::message::lookup "" intranet-workflow.All_Tasks "All Tasks"]</h3>\n$all_tasks"

    set unassigned_tasks ""
    if {$admin_p} {
	set unassigned_tasks [template::adp_parse $template_path [list package_url $package_url type unassigned]]
	set unassigned_tasks "<h3>[lang::message::lookup "" intranet-workflow.Unassigned_Tasks "Unassigned Tasks"]</h3>\n$unassigned_tasks"
    }
	
    
#    if {[string length own_tasks] < 50} { set own_tasks "" }
#    if {[string length all_tasks] < 50} { set all_tasks "" }
#    if {[string length unassigned_tasks] < 50} { set unassigned_tasks "" }

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
    # Check if there is a WF case with object_id as reference object
    set cases [db_list case "select case_id from wf_cases where object_id = :object_id"]

    switch [llength $cases] {
	0 {
	    # No case found - just return an empty string, 
	    # so that the component disappears
	    return ""
	}
	1 {
	    # Exactly one case found (default situation).
	    # Return the WF graph component
	    set size "3,4"
	    set params [list [list case_id [lindex $cases 0]] [list size $size]]
	    set result [ad_parse_template -params $params "/packages/acs-workflow/www/case-state-graph"]
	    return $result
	}
	default {
	    # More then one WF for this object.
	    # This is possible in terms of the WF structure,
	    # but not desired here.
	    return ""
	}
    }
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
