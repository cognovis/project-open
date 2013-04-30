# /www/admin/monitoring/top/index.tcl

ad_page_contract {
    Displays reports from saved top statistics.

   
} {
    
}

set title "TOP"
set context [list [list "index2" "TOP"] "Run"]

set top_location [ad_parameter -package_id [monitoring_pkg_id] TopLocation monitoring "/usr/local/bin/top"]
set top_options [ad_parameter -package_id [monitoring_pkg_id] TopOptions monitoring "-bn1"]


if [catch { set top_output [eval "exec $top_location $top_options"] } errmsg] {
        # couldn't exec top at TopLocation
        if { ![file exists $top_location] } {
        ad_return_error "top not found" "
        The top procedure could not be found at $top_location:
        <blockquote><pre> $errmsg </pre></blockquote>"
        return
        }
        
	if { [regexp "child process exited abnormally" $errmsg]  } {
        # this error means there was nothing on stderr (which makes sense) and
        # there was a non-zero exit code - this is OK as we intentionally send
        # stderr to stdout, so we just do nothing here (and return the output)
	
	#ns_log Error "ad_monitor_top: ok #### top_output: top_output"
	set top_output $errmsg

       } else {
	
        ad_return_error "top could not be run" "
    The top procedure at $top_location cannot be run:
    <blockquote><pre> $errmsg </pre></blockquote>"
        return  
	
       }
	
	
	
        
    }
    # top execution went ok
    append page_content "
    <h4>Current top output on this machine</h4>
    <pre>$top_output</pre>"
    

