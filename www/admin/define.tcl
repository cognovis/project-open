ad_page_contract {
    The advanced process builder main page.
        
    @author Lars Pind (lars@pinds.com)
    @creation-date 22 August 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    {format ""}
    {mode "normal"}
    {transition_key ""}
    {place_key ""}
} -validate {
    format_ok -requires { format } {
	if { ![string equal $format "html"] && ![string equal $format "graph"] && ![empty_string_p $format] } {
	    ad_complain "Illegal format. Choose html or graph."
	}
    }
    mode_ok -requires { mode } {
	if { [lsearch -exact { normal arcadd arcdelete } $mode] == -1 } {
	    ad_complain "Illegal mode."
	}
    }
    workflow_exists -requires { workflow_key:notnull } {
	if { [db_string wf_exists { select count(*) from wf_workflows where workflow_key = :workflow_key }] == 0 } {
	    ad_complain "Workflow doesn't exist"
	}
    }
    not_both_place_and_transition {
	if { ![empty_string_p $transition_key] && ![empty_string_p $place_key] } {
	    ad_complain "Not both transition and place"
	}
    }
} -properties {
    context
    mode
    transition_key
    place_key
    display
    header_stuff
    cancel_url
    workflow:onerow
    edit_links:multirow
    workflow_key
    transition:onerow
    input_places:multirow
    output_places:multirow
    place:onerow
    producing_transitions:multirow
    consuming_transitions:multirow
    modifiable_p
}


# ad_return_complaint 1 $workflow_key


#####
#
# Slurp up the workflow definition and release DB handles
#
#####

set workflow_info [wf_get_workflow_net $workflow_key]
array set workflow $workflow_info
db_1row num_cases {
    select count(*) as num_cases from wf_cases where workflow_key = :workflow_key
}
db_release_unused_handles

if { $num_cases > 0 } {
    set modifiable_p 0
} else {
    set modifiable_p 1
}


#####
#
# Make sure the selected transtion or place exists
#
#####

if { ![empty_string_p $transition_key] && ![info exists workflow(transition,$transition_key,transition_key)] } {
    set transition_key {}
}
if { ![empty_string_p $place_key] && ![info exists workflow(place,$place_key,place_key)] } {
    set place_key {}
}


#####
#
# Select the start place by default if there is one
#
#####

if { [empty_string_p $place_key] && [empty_string_p $transition_key] && \
	[info exists workflow(place,start,place_key)] } {
    set place_key "start"
}



#####
#
# Simple data sources 
#
#####

set header_stuff {}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow(pretty_name)"] "Edit process"]

set return_url "[ns_conn url]?[export_url_vars workflow_key format transition_key place_key]"

set cancel_url $return_url



#####
#
# Set Instructions
#
#####

set instructions {}

switch $mode {
    arcadd {
	if { ![empty_string_p $place_key] } {
	    set instructions "Select the task below where you want the arc to end."
	} else {
	    set instructions "Select the place below where you want the arc to end."
	}
    }
    arcdelete {
	set instructions "Select the end of the arc that you want to delete."
    }
}


#####
#
# Display logic (graphic/html)
#
#####

set graphviz_installed_p [wf_graphviz_installed_p]

switch -- $format {
    graph { 
	if { !$graphviz_installed_p } {
	    ns_log Warning "Tried to view a graphical display of workflow, but graphviz is not installed"
	    set format html
	}
    }
    "" {
	if { $graphviz_installed_p } {
	    set format graph
	} else {
	    set format html
	}
    } 
}

#####
#
# Decorate graph with links etc.
#
#####

wf_decorate_workflow \
	-format $format \
	-mode $mode \
	-selected_transition_key $transition_key \
	-selected_place_key $place_key \
	-return_url $return_url \
	workflow


#####
#
# Edit links
#
#####

template::multirow create edit_links url title
template::multirow append edit_links "task-add?[export_url_vars workflow_key]" "add task"
template::multirow append edit_links "place-add?[export_url_vars workflow_key]" "add place"

#####
#
# Format bar (HTML/Graphical)
#
#####

template::multirow create format_links url title selected_p
template::multirow append format_links "define?[export_ns_set_vars "url" {format}]&format=html" \
"HTML" [string equal $format "html"]
template::multirow append format_links "define?[export_ns_set_vars "url" {format}]&format=graph" \
	"Graphical" [string equal $format "graph"]

set wf_name [db_string wf_name "select pretty_name from acs_object_types where object_type=:workflow_key" -default ""]

ad_return_template

