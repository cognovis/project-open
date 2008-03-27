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
# Parse a single Nagios configuration file
# and return the definitions
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



# ----------------------------------------------------------------------
# Read a Nagios configuration (multiple files)
# and convert them into a "hosts" hash.
# ----------------------------------------------------------------------


ad_proc -public im_nagios_read_config {
    -main_config_file:required
    { -debug 1 }
} {
    Read multiple configuration files and return a "hosts" hash structure.
    Write out debug lines to the HTTP session via ns_write.
} {

    # ------------------------------------------------------------
    # Read the main config file
    #
    
    set encoding "utf-8"
    
    if {[catch {
	set fl [open $main_config_file]
	fconfigure $fl -encoding $encoding
	set content [read $fl]
	close $fl
    } err]} {
	ns_write "<li>Unable to open file $main_config_file:<br><pre>\n$err</pre>"
	ns_write [im_footer]
	return {}
    }
    
    set config_files [list]
    foreach line [split $content "\n"] {
	set line [string trim $line]
	if {"" == $line} { continue}
	if {[regexp {^\#} $line]} { continue}
	if {[regexp {cfg_file=(.*)} $line match config_file]} { lappend config_files $config_file }
    }


    # ------------------------------------------------------------
    # Read and parse the object files
    #
    
    set lines [list]
    foreach config_file $config_files {
	
	if {$debug} { ns_write "<h3>Parsing file: $config_file</h3>\n" }
	if {[catch {
	    set fl [open $config_file]
	    fconfigure $fl -encoding $encoding
	    set content [read $fl]
	    close $fl
	} err]} {
	    ns_write "<li>Unable to open file $config_file:<br><pre>\n$err</pre>"
	    ns_write [im_footer]
	    return {}
	}

	set lines [split $content "\n"]
	set defs [im_nagios_parse_config_file -lines $lines]
	
	array unset file_defs
	array set file_defs $defs
	foreach def_id [array names file_defs] {
	    
	    # Read the definition into a hash in order to make processing easier.
	    # "defs" come in the form: {{type host} {use template} {host_name router123} {pretty_name {Disk Service 123}} ...}
	    set defs $file_defs($def_id)
	    array unset def_hash
	    foreach def $defs {
		set key [lindex $def 0]
		set value [lindex $def 1]
		set def_hash($key) $value
	    }
	    
	    # Get the type of definition and extract values
	    if {![info exists def_hash(type)]} { continue }
	    set def_type $def_hash(type)
	    switch $def_type {
		command - timeperiod - contact - contactgroup - hostgroup {
		    # No action required.
		}
		host {
		    # define host {use linux-server host_name storage02 alias {Storage 02} address 172.26.2.7}
		    if {[catch {
			
			# Pull out the hostname. 
			set name "unknown"
			if {[info exists def_hash(name)]} { set host_name $def_hash(name) }
			if {[info exists def_hash(host_name)]} { set host_name $def_hash(host_name) }
			
			# Store the host definition in hosts hash
			set hosts_def [list]
			if {[info exists hosts($host_name)]} { set hosts_def $hosts($host_name) }
			lappend hosts_def [list host [array get def_hash]]
			set hosts($host_name) $hosts_def
			
			# Write out log line
			if {$debug} { ns_write "<li>Found host=$host_name\n" }
			
		    } err_msg]} {
			ns_write "<p class=error>
			Error parsing '$def_type' definition in file '$config_file':
			<pre>$err_msg</pre><br>[array get def_hash]</p>\n
		    "
		    }
		}
		service {
		    # define service {use generic-service host_name storage02 service_description {Current Load} ...}
		    if {[catch {
			
			# Pull out the service name
			set host_name "unknown"
			if {[info exists def_hash(host_name)]} { set host_name $def_hash(host_name) }
			set service_description "unknown"
			if {[info exists def_hash(service_description)]} { set service_description $def_hash(service_description) }
			
			# Store the service definition in hosts hash
			set hosts_def [list]
			if {[info exists hosts($host_name)]} { set hosts_def $hosts($host_name) }
			lappend hosts_def [list $service_description [array get def_hash]]
			set hosts($host_name) $hosts_def
			
			# Write out log line
			if {$debug} { ns_write "<li>Found service=$name\n" }
			
		    } err_msg]} {
			ns_write "<p class=error>
			Error parsing '$def_type' definition in file '$config_file':
			<pre>$err_msg</pre><br>[array get def_hash]</p>\n
		    "
		    }
		}
		default {
		    if {$debug} { ns_write "<p class=error>Unknown definition '$def_type'</p>\n" }
		}
	    }
	}
	
    }
    return [array get hosts]
}
