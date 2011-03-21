# intranet-workflow/www/flatten-workflow.tcl

ad_page_contract {

} {
    workflow_key
}



im_workflow_graph_sort_order $workflow_key

ad_return_complaint 1 updated



set html ""

append html "<h2>Arcs</h2><ul>\n"
db_foreach transitions {
        select *
        from wf_arcs
        where workflow_key = :workflow_key
} {
    append html "<li>transition=$transition_key, place=$place_key, dir=$direction\n"

    set distance($place_key) 9999999999
    set distance($transition_key) 9999999999

    switch $direction {
	in {
	    lappend edges [list $place_key $transition_key]
	}
	out {
	    lappend edges [list $transition_key $place_key]
	}
    }
}
append html "</ul>\n"



# distance - Mapping from places & transitions to distance from start
# edges - List of directed edges


set active_nodes [list start]
set distance(start) 0

append html "<h2>Distance</h2><ul>\n"
set cnt 0
while {$cnt < 20 && [llength $active_nodes] > 0} {
    incr cnt
    append html "<li>cnt=$cnt, active_nodes=$active_nodes\n"

    set active_node [lindex $active_nodes 0]
    set active_nodes [lrange $active_nodes 1 end]

	foreach edge $edges {

	    set from [lindex $edge 0]
	    set to [lindex $edge 1]
#	    append html "<li>active=$active_node, from=$from, to=$to\n"

	    # Check if we find and outgoing edge from node
	    if {[string equal $from $active_node]} {

		set dist1 [expr $distance($from) + 1]
#		append html "<li>match: dist1=$dist1\n"

		if {$dist1 < $distance($to)} {
		    set distance($to) $dist1
		    append html "<li>distance($to) = $dist1\n"

		    # Append the new to-node to the end of the active nodes.
		    lappend active_nodes $to
		}
	    }
	}

}
append html "</ul>\n"
append html "<li>edges=$edges\n"
ad_return_complaint 1 $html




array set wf_info [wf_workflow_info $workflow_key]
# ad_return_complaint 1 [array get wf_info]

set transitions $wf_info(transitions)
# ad_return_complaint 1 $transitions

set html ""
foreach transition $transitions {

    append html "<li>$transition"
}



