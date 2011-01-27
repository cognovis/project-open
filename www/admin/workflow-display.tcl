# packages/acs-workflow/www/admin/workflow-display.tcl
# @author Lars Pind (lars@pinds.com)
# @creation-date November 21, 2000
# @cvs-id $Id$
#
# Expects
#     workflow:onerow (the representation of the workflow net)
#     workflow_key
#     format (html,graph)
#     mode
#     transition_key
#     place_key
#     header_stuff (ref)
#     return_url
# Returns
#    display
#    header_stuff

switch $format {
    graph {
	set dot_text [wf_generate_dot_representation workflow]

	set tmpfile [wf_graphviz_dot_exec -to_file -output gif $dot_text]
	
	set width_and_height ""
	if { ![catch { set image_size [ns_gifsize $tmpfile] } error] } {
	    if { ![empty_string_p $image_size] } {
		set width_and_height "width=[lindex $image_size 0] height=[lindex $image_size 1]"
	    }
	}

	ad_set_client_property wf wf_net_tmpfile $tmpfile

	ns_log Notice "workflow-display: \[wf_graphviz_dot_exec -to_file -output ismap $dot_text\]"
	set output_file [wf_graphviz_dot_exec -to_file -output ismap $dot_text]

	# Read the output_file
	if {[catch {
	    set fl [open $output_file]
	    set ismap [read $fl]
	    close $fl
	    file delete $output_file
	} err]} {
	    ad_return_complaint 1 "Unable to read or delete file $output_file:<br><pre>\n$err</pre>"
	    return ""
	}

	# Convert into a ckickable map
	set header_stuff [wf_ismap_to_client_map -name "wf_map" $ismap]

	set display "
	<img src=\"/[im_workflow_url]/workflow-gif?[export_url_vars tmpfile]\" border=0 usemap=\"#wf_map\" $width_and_height alt=\"Graphical representation of the process network\">
	"
    }
    html {
	template::multirow create transitions transition_key 
	foreach loop_transition_key $workflow(transitions) {
	    template::multirow append transitions $loop_transition_key
	}
	
	template::multirow create places place_key
	foreach loop_place_key $workflow(places) {
	    template::multirow append places $loop_place_key
	}
    }
}

ad_return_template
