#
# Display the workflow process graphically
#
# Expects:
#   workflow_key
#   size (optional)
# Data sources
#   workflow_img_tag
#

#####
#
# Add marking to the graph
#
#####

set workflow_info [wf_get_workflow_net $workflow_key]
array set workflow $workflow_info
wf_decorate_workflow workflow

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

    if {[catch {
	set tmpfile [wf_graphviz_dot_exec -to_file -output gif $dot_text]
    } err_msg]} {
	ad_return_complaint 1 "<b>Error rendering workflow</b>:<br><pre>$err_msg</pre>"
    }


    set width_and_height ""
    if { ![catch { set image_size [ns_gifsize $tmpfile] } error] } {
	if { ![empty_string_p $image_size] } {
	    set width_and_height "width=[lindex $image_size 0] height=[lindex $image_size 1]"
	}
    }
    
    ad_set_client_property wf wf_net_tmpfile $tmpfile
    
    set workflow_img_tag "<img src=\"/[im_workflow_url]/workflow-gif?[export_url_vars tmpfile]\" border=0 $width_and_height alt=\"Graphical representation of the process network\">"
} else {
    set workflow_img_tag ""
}

