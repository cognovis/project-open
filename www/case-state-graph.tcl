#
# Display the state of a case graphically
#
# Expects:
#   case_id
#   size (optional)
# Data sources
#   workflow_img_tag
#

#####
#
# Add marking to the graph
#
#####

set workflow_url [apm_package_url_from_key "acs-workflow"]
set workflow_key [db_string workflow_key_from_case_id { select workflow_key from wf_cases where case_id = :case_id }]

set workflow_info [wf_get_workflow_net $workflow_key]
array set workflow $workflow_info
wf_decorate_workflow workflow

foreach place_key $workflow(places) {
    set workflow(place,$place_key,num_tokens) 0
}
foreach transition_key $workflow(transitions) {
    set workflow(transition,$transition_key,num_tokens) 0
}

db_foreach tokens {
    select tok.token_id, 
           tok.place_key,
           tok.locked_task_id,
           ta.transition_key
    from   wf_tokens tok,
           wf_tasks ta
    where  tok.case_id = :case_id
    and    ta.task_id (+) = tok.locked_task_id
    and    tok.state in ('free', 'locked')
} {
    if { [empty_string_p $transition_key] } {
	incr workflow(place,$place_key,num_tokens)
    } else {
	incr workflow(transition,$transition_key,num_tokens)
    }
}

foreach place_key $workflow(places) {
    if { $workflow(place,$place_key,num_tokens) > 0 } {
	append workflow(place,$place_key,place_name) "\\n[string repeat "*" $workflow(place,$place_key,num_tokens)]"
	lappend workflow(selected_place_key) $place_key
    }
}
foreach transition_key $workflow(transitions) {
    if { $workflow(transition,$transition_key,num_tokens) > 0 } {
	append workflow(transition,$transition_key,transition_name) "\\n[string repeat "*" $workflow(transition,$transition_key,num_tokens)]"
	lappend workflow(selected_transition_key) $transition_key
    }
}

db_release_unused_handles

#####
#
# Create the workflow gif
#
#####

if { [wf_graphviz_installed_p] } {

    if { ![info exists size] } {
	set size {}
    }

    set dot_text [wf_generate_dot_representation -size $size workflow]
    
    set tmpfile [wf_graphviz_dot_exec -to_file -output gif $dot_text]
    
    set width_and_height ""
    if { ![catch { set image_size [ns_gifsize $tmpfile] } error] } {
	if { ![empty_string_p $image_size] } {
	    set width_and_height "width=[lindex $image_size 0] height=[lindex $image_size 1]"
	}
    }
    
    ad_set_client_property wf wf_net_tmpfile $tmpfile
    
    set workflow_img_tag "<img src=\"${workflow_url}workflow-gif?[export_url_vars tmpfile]\" border=0 $width_and_height alt=\"Graphical representation of the process network\">"
} else {
    set workflow_img_tag ""
}

