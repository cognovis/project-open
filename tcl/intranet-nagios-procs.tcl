# /packages/intranet-nagios/tcl/intranet-nagios-procs.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_nagios_xxx {} { return 0 }


# ----------------------------------------------------------------------
# Parse a Nagios configuration file
# ----------------------------------------------------------------------


ad_proc -public im_nagios_parse_config_file {
    -lines:required
} {
    The Nagios parser. Accepts a list of (cleaned up) lines
    from a Nagios configuration file and returns a list of service 
    definitions in a format suitable for "array set":
    {
	1 {{type host} {use template} {host_name router123} {pretty_name {Disk Service 123}} ...}
	2 {{type host} {use template} {host_name router234} {pretty_name {Disk Service 345}} ...}
	...
    }
    The numeration is arbitrary and kept just for convenience reasons.
} {
    array set services_hash [list]
    set service_cnt 1
    set cur_service 0

    # Go through all lines of the file and sort the lines into a "service_list".
    foreach line $lines {
	
	# ---------------------------------------------------------
	# Preprocess the lines and filter out comments

	# Remove ";" comments
	if {[regexp {^(.*)\;} $line match payload]} { set line $payload }

	# Remove leading and trailing spaces
	set line [string trim $line]

	# Discard empty lines
	if {"" == $line} { continue }
	
	# Discard comment lines
	if {[regexp {^\#} $line]} { continue }
	
	# Put spaces around "{" and "}"
	regsub -all {\{} $line " \{ " line
	regsub -all {\}} $line " \} " line
	
	# Replace multiple white spaces by a single space
	regsub -all {[ \t]+} $line " " line

	# Cleanup too many white spaces
	set line [string trim $line]

	# ---------------------------------------------------------
	# Start a new service definitioin everytime we find a line
	# that starts with "define".
	if {[regexp {^define ([a-zA-Z0-9_]+)} $line match service]} {

	    # Start a new service definition
	    incr service_cnt
	    set cur_service $service_cnt

	    # Set the "type" of the new service.
	    set service_def [list [list type $service]]

	    set services_hash($service_cnt) $service_def
	    continue
	}

	# ---------------------------------------------------------
	# We've found the end of a definition. 
	if {[regexp {^\}} $line match]} {

	    # Reset the cur_service to 0 for non-valid lines
	    set cur_service 0
	    continue
	}
  
	# ---------------------------------------------------------
	# Parse one of the definition lines. Treat the line as a list...
	set key [lindex $line 0]
	set values [lrange $line 1 end]

	set service_def $services_hash($cur_service)
	lappend service_def [list $key $values]
	set services_hash($cur_service) $service_def

    }

    return [array get services_hash]
#    ad_return_complaint 1 "<pre>[join [array get services_hash] "\n"]</pre>"

}




