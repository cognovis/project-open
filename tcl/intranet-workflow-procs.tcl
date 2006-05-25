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

ad_proc -public wf_workflow_list_options {
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
    set all_tasks [template::adp_parse $template_path [list package_url $package_url]]

    if {[string length own_tasks] < 50} { set own_tasks "" }
    if {[string length unassigned_tasks] < 50} { set unassigned_tasks "" }

    set component_html "
<table cellspacing=1 cellpadding=0>
<tr><td>
$own_tasks
$all_tasks
</td></tr>
</table>
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

