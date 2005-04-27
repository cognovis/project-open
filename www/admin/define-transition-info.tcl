# packages/acs-workflow/www/admin/define-transition-info.tcl
# @author Lars Pind (lars@pinds.com)
# @creation-date November 21, 2000
# @cvs-id $Id$
#
# Expects:
#    workflow:onerow (the magic thing)
#    transition_key
#    mode
#    format
#    return_url
#    modifiable_p (optional)
# Returns:
#    workflow_key
#    transition:onerow(transition_key, transition_name, arc_add_url, arc_delete_url, edit_url, delete_url)
#    input_places:multirow(url, place_key, place_name, arc_delete_url)
#    output_places:multirow(url, place_key, place_name, arc_delete_url, 
#                           guard_pretty, guard_edit_url, guard_delete_url, guard_add_url)

set workflow_key $workflow(workflow_key)

if { ![info exists modifiable_p] } {
    set modifiable_p 1
}

# transition:onerow(transition_key, transition_name, arc_add_url, arc_delete_url, edit_url, delete_url)

set transition(transition_key) $transition_key
set transition(transition_name) $workflow(transition,$transition_key,transition_name)
set transition(edit_url) "task-edit?[export_url_vars workflow_key transition_key return_url]"
if { $modifiable_p } {
    set transition(delete_url) "task-delete?[export_url_vars workflow_key transition_key return_url]"
    set transition(arc_add_url) "define?[export_ns_set_vars {url} {mode}]&mode=arcadd"
    set transition(arc_delete_url) "define?[export_ns_set_vars {url} {mode}]&mode=arcdelete"
} else {
    set transition(delete_url) ""
    set transition(arc_add_url) ""
    set transition(arc_delete_url) ""
}
#set transition(panels_url) "task-panels?[export_vars -url {workflow_key transition_key return_url}]"
set transition(assignment_url) "task-assignment?[export_vars -url {workflow_key transition_key return_url}]"
set transition(attributes_url) "task-attributes?[export_vars -url {workflow_key transition_key return_url}]"
set transition(actions_url) "task-actions?[export_vars -url {workflow_key transition_key return_url}]"

# input_places:multirow(url, place_key, place_name, arc_delete_url)

template::multirow create input_places place_key place_name url arc_delete_url

set direction "in"
foreach loop_place_key $workflow(arcs,transition,$transition_key,in) {
    set url "define?[export_url_vars workflow_key place_key=[ns_urlencode $loop_place_key] format]"
    if { $modifiable_p } {
	set arc_delete_url "arc-delete?[export_url_vars workflow_key transition_key place_key=[ns_urlencode $loop_place_key] direction return_url]"
    } else {
	set arc_delete_url ""
    }
    template::multirow append input_places $loop_place_key $workflow(place,$loop_place_key,place_name) $url $arc_delete_url
}

# output_places:multirow(url, place_key, place_name, arc_delete_url, 
#                        guard_pretty, guard_edit_url, guard_delete_url, guard_add_url)

template::multirow create output_places place_key place_name url arc_delete_url \
	guard_pretty guard_edit_url guard_delete_url guard_add_url

set direction "out"
foreach loop_place_key $workflow(arcs,transition,$transition_key,out) {
    set url "define?[export_url_vars workflow_key place_key=[ns_urlencode $loop_place_key] format]"
    if { $modifiable_p } {
	set arc_delete_url "arc-delete?[export_url_vars workflow_key transition_key place_key=[ns_urlencode $loop_place_key] direction return_url]"
    } else {
	set arc_delete_url ""
    }
    set guard_pretty [ad_decode $workflow(arc,$transition_key,$loop_place_key,out,guard_description) \
	    "" $workflow(arc,$transition_key,$loop_place_key,out,guard_callback) \
	    $workflow(arc,$transition_key,$loop_place_key,out,guard_description)]
    set guard_edit_url "arc-edit?[export_url_vars workflow_key transition_key place_key=[ns_urlencode $loop_place_key] direction return_url]"
    set guard_delete_url "arc-edit-2?[export_url_vars workflow_key transition_key place_key=[ns_urlencode $loop_place_key] direction return_url]&guard_callback=&guard_custom_arg=&guard_description="
    set guard_add_url "arc-edit?[export_url_vars workflow_key transition_key place_key=[ns_urlencode $loop_place_key] direction return_url]"
    template::multirow append output_places $loop_place_key $workflow(place,$loop_place_key,place_name) $url $arc_delete_url \
	    $guard_pretty $guard_edit_url $guard_delete_url $guard_add_url
}

ad_return_template

