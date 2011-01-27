ad_library { 
    Helper procs for generating graphical representations of workflows.

    @author Lars Pind (lars@pinds.com)
    @creation-date September 15, 2000
    @cvs-id $Id$
}


ad_proc wf_get_workflow_net_internal {
    workflow_key
} {
    set workflow(transitions) {}
    set workflow(places) {}
    set workflow(arcs) {}

    set workflow(pretty_name) [db_string workflow_name \
	    { select pretty_name from acs_object_types where object_type = :workflow_key }]
    set workflow(workflow_key) $workflow_key
    
    db_foreach transition_def {
	select transition_key,
	       transition_name,
	       sort_order,
	       trigger_type
	from   wf_transitions
	where  workflow_key = :workflow_key
	order  by sort_order
    } {
	lappend workflow(transitions) $transition_key
	set workflow(transition,$transition_key,transition_key) $transition_key
	set workflow(transition,$transition_key,transition_name) $transition_name
	set workflow(transition,$transition_key,sort_order) $sort_order
	set workflow(transition,$transition_key,trigger_type) $trigger_type

	set workflow(arcs,transition,$transition_key,in) [list]
	set workflow(arcs,transition,$transition_key,out) [list]
    }
    
    db_foreach places_def {
	select p.place_key,
	       p.place_name,
	       p.sort_order
	from   wf_places p
	where  p.workflow_key = :workflow_key
	order  by p.sort_order
    } {
	lappend workflow(places) $place_key
	set workflow(place,$place_key,place_key) $place_key
	set workflow(place,$place_key,place_name) $place_name
	set workflow(place,$place_key,sort_order) $sort_order
	
	set workflow(arcs,place,$place_key,in) [list]
	set workflow(arcs,place,$place_key,out) [list]
    }

    db_foreach arcs_def {
	select transition_key,
	       place_key,
	       direction,
	       guard_callback,
	       guard_custom_arg,
	       guard_description
	from   wf_arcs
	where  workflow_key = :workflow_key
    } {
	# lets you say workflow(arc,$arc), where $arc is an element from this list.
	lappend workflow(arcs) "$transition_key,$place_key,$direction"
	
	# makes it possible to easily get the input/output places for a given transition
	lappend workflow(arcs,transition,$transition_key,$direction) $place_key
	# ... and for a given place
	lappend workflow(arcs,place,$place_key,$direction) $transition_key
	
	set workflow(arc,$transition_key,$place_key,$direction,guard_callback) $guard_callback
	set workflow(arc,$transition_key,$place_key,$direction,guard_custom_arg) $guard_custom_arg
	set workflow(arc,$transition_key,$place_key,$direction,guard_description) $guard_description
	
	# makes it easier to know what direction to draw the arrow in
	set workflow(arc,$transition_key,$place_key,$direction,from) \
		[ad_decode $direction "in" "place,$place_key" "transition,$transition_key"]
	set workflow(arc,$transition_key,$place_key,$direction,to) \
		[ad_decode $direction "in" "transition,$transition_key" "place,$place_key"]
		
    }

    return [array get workflow]
}

ad_proc wf_get_workflow_net {
    workflow_key
} {
    We cache the workflow net, although we don't really need that anymore.
} {
    return [ns_cache eval workflow_info $workflow_key {wf_get_workflow_net_internal $workflow_key}]
}

ad_proc wf_workflow_changed {
    workflow_key
} { 
    Flushes the cache.
} {
    ns_cache flush workflow_info $workflow_key
}


ad_proc wf_decorate_workflow {
    {-mode "normal"}
    {-format "graph"}
    {-selected_transition_key ""}
    {-selected_place_key ""}
    {-return_url ""}
    workflow_varname
} {
    Adds linking information to the workflow net, based on the arguments given.
} {
    upvar 1 $workflow_varname workflow

    #####
    #
    # Establish links for the graph
    #
    #####
    
    set place_link {}
    set transition_link {}
    set nolink [list]
    set onlylink [list]

    switch $mode {
	normal {
	    set transition_link "define?[export_url_vars format mode]&"
	    set place_link "define?[export_url_vars format mode]&"
	}
	arcadd {
	    if { ![empty_string_p $selected_place_key] } {
		set direction in
		set place_link {}
		set transition_link "arc-add?[export_url_vars place_key=[ns_urlencode $selected_place_key] direction return_url]&"
		foreach loop_transition_key $workflow(arcs,place,$selected_place_key,in) {
		    lappend nolink "transition,$loop_transition_key"
		}
	    } else {
		set direction out
		set transition_link {}
		set place_link "arc-add?[export_url_vars transition_key=[ns_urlencode $selected_transition_key] direction return_url]&"
		foreach loop_place_key $workflow(arcs,transition,$selected_transition_key,out) {
		    lappend nolink "place,$loop_place_key"
		}
	    }
	}
	arcdelete {
	    if { ![empty_string_p $selected_place_key] } {
		set direction in
		set place_link {}
		set transition_link "arc-delete?[export_url_vars place_key=[ns_urlencode $selected_place_key] direction return_url]&"
		foreach loop_transition_key $workflow(arcs,place,$selected_place_key,in) {
		    lappend onlylink "transition,$loop_transition_key"
		}
	    } else {
		set direction out
		set transition_link {}
		set place_link "arc-delete?[export_url_vars transition_key=[ns_urlencode $selected_transition_key] direction return_url]&"
		foreach loop_place_key $workflow(arcs,transition,$selected_transition_key,out) {
		    lappend onlylink "place,$loop_place_key"
		}
	    }
	}
    }

    if { [empty_string_p $onlylink] && [empty_string_p $nolink] && \
	    ![empty_string_p $transition_link] && ![empty_string_p $place_link] } {
	set arc_color black
    } else {
	set arc_color grey
    }

    set workflow(place_link) $place_link
    set workflow(transition_link) $transition_link
    set workflow(nolink) $nolink
    set workflow(onlylink) $onlylink
    set workflow(selected_transition_key) $selected_transition_key
    set workflow(selected_place_key) $selected_place_key
    set workflow(arc_color) $arc_color

    #####
    # 
    # Translate this into the representation
    # (this is the same for both HTML and graphical representation)
    #
    #####

    # to make export_url_vars easier
    set workflow_key $workflow(workflow_key)

    foreach type { transition place } {
	foreach key $workflow(${type}s) {
	    if { [empty_string_p $onlylink] } {
		set workflow($type,$key,url) [ad_decode \
			[set ${type}_link] \
			"" "" \
			"[set ${type}_link][export_url_vars workflow_key ${type}_key=[ns_urlencode $key]]"]
	    } else {
		set workflow($type,$key,url) {}
	    }
	}
    }
    foreach key $onlylink {
	set type [lindex [split $key ","] 0]
	set type_key [lindex [split $key ","] 1]
	set workflow($key,url) [ad_decode \
		[set ${type}_link] \
		"" "" \
		"[set ${type}_link][export_url_vars workflow_key ${type}_key=[ns_urlencode ${type_key}]]"]
    }
    foreach key $nolink {
	set workflow($key,url) {}
    }
}



ad_proc wf_generate_dot_representation {
    {-orientation portrait}
    {-rankdir UD}
    {-size}
    {-debug 0 }
    workflow_varname
} {
    Generates a dot-file for use with Graphviz.
    From such a dot-file, we can generate both a GIF image and an imagemap.
    
    @param Tcl representation of a workflow net, as returned by <code>wf_get_workflow_net</code>.

    @author Lars Pind (lars@pinds.com)
    @creation-date 28 September 2000
} {
    upvar 1 $workflow_varname workflow

    set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow'}]

    set transition_font_name [ad_parameter -package_id $package_id "transition_font_name"]
    set place_font_name [ad_parameter -package_id $package_id "place_font_name"]
    set guard_font_name [ad_parameter -package_id $package_id "guard_font_name"]
    set transition_font_size [ad_parameter -package_id $package_id "transition_font_size"]
    set place_font_size [ad_parameter -package_id $package_id "place_font_size"]
    set guard_font_size [ad_parameter -package_id $package_id "guard_font_size"]

    # Add graph-specific info to the data structure
    foreach type { transition place } {
	foreach key $workflow(${type}s) {
	    set workflow($type,$key,style) solid
	    set workflow($type,$key,shape) [ad_decode $type "transition" "box" "circle"]
	    set workflow($type,$key,label) [ad_decode $type "transition" $workflow($type,$key,${type}_name) ""]
	    set workflow($type,$key,peripheries) 1
	    set workflow($type,$key,fontname) [ad_decode $type "transition" $transition_font_name $place_font_name]
	    set workflow($type,$key,fontsize) [ad_decode $type "transition" $transition_font_size $place_font_size]
	    set workflow($type,$key,height) [ad_decode $type "transition" 0.4 0.2]
	    set workflow($type,$key,width) [ad_decode $type "transition" 0.4 0.2]
	    
	    set workflow($type,$key,URL) $workflow($type,$key,url)
	    if { ![empty_string_p $workflow($type,$key,URL)] } {
		set workflow($type,$key,color) black
	    } else {
		set workflow($type,$key,color) grey
	    }
	    set workflow($type,$key,fontcolor) $workflow($type,$key,color) 

	    #set workflow($type,$key,fillcolor) blue
	    #set workflow($type,$key,color) black
	    #set workflow($type,$key,style) filled

	    if { [string equal $type "place"] } {
		switch $workflow($type,$key,${type}_key) {
		    start {
			append workflow($type,$key,label) {S}
			set workflow($type,$key,peripheries) 2
		    }
		    end {
			append workflow($type,$key,label) {E}
			set workflow($type,$key,peripheries) 2
		    }
		    default {
			set workflow($type,$key,fontsize) 1
		    }
		}
	    }
	    if { [string equal $type transition] && ![string equal $workflow($type,$key,trigger_type) user] } {
		append workflow($type,$key,label) "\\n($workflow($type,$key,trigger_type))"
	    }

	}
    }

    if { ![empty_string_p $workflow(selected_transition_key)] } {
	foreach selected_transition_key $workflow(selected_transition_key) {
	    set workflow(transition,$selected_transition_key,color) blue
	    set workflow(transition,$selected_transition_key,style) filled
	    set workflow(transition,$selected_transition_key,fontcolor) white
	}
    }
    if { ![empty_string_p $workflow(selected_place_key)] } {
	foreach selected_place_key $workflow(selected_place_key) {
	    set workflow(place,$selected_place_key,color) blue
	    set workflow(place,$selected_place_key,style) filled
	    set workflow(place,$selected_place_key,fontcolor) white
	}
    }

    set dot_text "digraph workflow {\n"
    append dot_text "        orientation=$orientation;\n"
    append dot_text "        rankdir=$rankdir;\n"
    append dot_text "        ratio=compress;\n"
    if { [info exists size] && ![empty_string_p $size] } {
        append dot_text "        size=\"$size\";\n"
    }

    foreach place_key $workflow(places) {
	set attributes [list]
	foreach attr { fontsize label URL color fontname fontcolor style shape peripheries fillcolor height width fixedsize } {
	    if { [info exists workflow(place,$place_key,$attr)] } {
		set val $workflow(place,$place_key,$attr)
		regsub -all {"} $val {\"} val
		lappend attributes "$attr=\"$val\"" 
	    }
	}
	append dot_text "        node \[ [join $attributes " "] \]; \"place,$place_key\";\n"
    }

    foreach transition_key $workflow(transitions) {
	set attributes [list]
	foreach attr { fontsize label URL color fontname fontcolor style shape peripheries fillcolor height width fixedsize } {
	    if { [info exists workflow(transition,$transition_key,$attr)] } {
		set val $workflow(transition,$transition_key,$attr)
		regsub -all {"} $val {\"} val
		lappend attributes "$attr=\"$val\"" 
	    }
	}
	append dot_text "        node \[ [join $attributes " "] \]; \"transition,$transition_key\";\n"
    }

    foreach arc $workflow(arcs) {
	set attributes [list]
	set guard [ad_decode $workflow(arc,$arc,guard_description) \
		"" $workflow(arc,$arc,guard_callback) $workflow(arc,$arc,guard_description)]
	regsub -all {"} $guard {\"} guard
	lappend attributes "label=\"[ad_decode $guard "" "" "\[ $guard \]"]\""
	lappend attributes "fontname=\"$guard_font_name\""
	lappend attributes "fontsize=\"$guard_font_size\""
	lappend attributes "fontcolor=red"
	lappend attributes "color=$workflow(arc_color)"
        lappend attributes "minlen=1"
        #lappend attributes "decorate=1"
	append dot_text "        \"$workflow(arc,$arc,from)\" -> \"$workflow(arc,$arc,to)\" \[ [join $attributes " "] \]; \n"
    }
    
    append dot_text "}"

    if {$debug} { ns_log Notice "wf_generate_dot_representation: $dot_text" }

    return $dot_text
}

ad_proc wf_graphviz_dot_exec {
    {-output ismap}
    {-to_file:boolean}
    dot
} {
    Implementation of wf_graphviz_dot_exec.
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September 2000
} {
    ns_log Notice "wf_graphviz_dot_exec: -to_file=$to_file_p -output=$output dot=$dot"
    set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow'}]
    set graphviz_dot_path [ad_parameter -package_id $package_id "graphviz_dot_path"]
    set tmp_path [ad_parameter -package_id $package_id "tmp_path"]

    if { [empty_string_p $graphviz_dot_path] } {
	return -code error "Graphviz is not installed."
    }

#    091031 fraber: Doesn't work like this with Windows installer.
#    if { ![file executable $graphviz_dot_path] } {
#	return -code error "Can't execute graphviz binary at $graphviz_dot_path"
#    }

#    091103 fraber: Doesn't work like this with Windows installer.
#    if { ![file isdirectory $tmp_path] } {
#	return -code error "Parameter acs-workflow.tmp_path points to a non-existing directory: $tmp_path"
#    }

    set output [string tolower $output]
    if { [regexp {[^a-z]} $output] } {
	return -code error "Only a-z allowed in 'output'"
    }

    set tmp_dot [ns_mktemp "$tmp_path/dotXXXXXX"]
    if { $to_file_p } {
	set tmp_out [ns_mktemp "$tmp_path/outXXXXXX"]
    }

    # Write the DOT definition into the temporary input file
    set fw [open $tmp_dot "w"]
    puts -nonewline $fw $dot
    close $fw
    
    if {[catch {
	if { $to_file_p } {
	    exec -keepnewline $graphviz_dot_path -T$output -o $tmp_out $tmp_dot
	    ns_log Notice "wf_graphviz_dot_exec: exec -keepnewline $graphviz_dot_path -T$output -o $tmp_out $tmp_dot"
	} else {
	    set result [exec -keepnewline $graphviz_dot_path -T$output $tmp_dot]
	    ns_log Notice "wf_graphviz_dot_exec: exec -keepnewline $graphviz_dot_path -T$output $tmp_dot"
	    ad_return_complaint 1 $result
	}
    } err_msg]} {
	
	# Check for error with graphviz 2.8
	if {[regexp {Layout was not done} $err_msg match]} { 
	    ad_return_complaint 1 "
		<b>Error executing 'dot' GraphViz</b>:<br>&nbsp;<br>
		This error message probably means that GraphViz's
		plugins are not yet configured.<br>
		To configure the plugins please:
		<ol>
		<li>Log in as root.
		<li>Execute: <tt>dot -c</tt>
		</ol>
		<br>
		Here is the original error message:<br>
		<pre>$err_msg</pre><br>

	    "
	    ad_script_abort
	}

	ad_return_complaint 1 "
		<b>Error executing 'dot' GraphViz</b>:<br>&nbsp;<br>
		We have encountered an error executing the GraphViz external
		appliction to render your workflow graph. <br>
		Here is the detailed error message:<br>&nbsp;<br>
		<pre>$err_msg</pre>
	"
    }

    # Delete the temporary _input_ file for dot.
    # (the output file remains).
    file delete $tmp_dot

    if { $to_file_p } {
	return $tmp_out
    } else {
	return $result
    }
}

ad_proc wf_graphviz_installed_p {} {
    Will tell you whether the AT&T GraphViz package is installed or not.
    Just checks to see if the parameter is set.

    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September 2000
} {
    set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow'}]
    set graphviz_dot_path [ad_parameter -package_id $package_id "graphviz_dot_path"]

    return [expr ![empty_string_p $graphviz_dot_path]]

}


ad_proc wf_ismap_to_client_map {
    {-name "map"}
    ismap
} {
    Translates a server-side imagemap as generated by graphviz into a client-side imagemap
    that you can include in your HTML.

    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September 2000

} {
    set client_map "<map name=\"$name\">\n"
    
    set lines [split $ismap "\n"]
    foreach line $lines {
        if { [regexp {^\s*([^\s]+)\s+\(([0-9]+),([0-9]+)\)\s+\(([0-9]+),([0-9]+)\)\s+([^\s]+)(.*)$} $line match shape c1 c2 c3 c4 href alt] } {
            append client_map "<area shape=\"[ad_decode $shape "rectangle" "rect" $shape]\" coords=\"$c1,$c4,$c3,$c2\" href=\"$href\" alt=\"$alt\">\n"
        }
    }
    append client_map "</map>\n"

    return $client_map
}


