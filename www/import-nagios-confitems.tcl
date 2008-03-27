# /packages/intranet-nagios/www/import-nagios-confitems.tcl

ad_page_contract {
    Parses the Nagios configuration file and creates ConfItems in the
   ]po[ ConfDB
} {
    { return_url "index" }
}

# ------------------------------------------------------------
# Default & Security
#

set user_id [ad_maybe_redirect_for_registration]
set page_title [_ intranet-nagios.Import_Nagios_Configuration]
set context_bar [im_context_bar $page_title]
set context ""

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set main_config_file [parameter::get_from_package_key -package_key "intranet-nagios" -parameter "NagiosConfigurationUnixPath" -default "/usr/local/nagios/etc/nagios.cfg"]

# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<H1>$page_title</H1>\n"
ns_write "<h2>Configuration</h2>\n"
ns_write "<ul>\n"
ns_write "<li>Nagios Configuration File: $main_config_file\n"
ns_write "</ul>\n"


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
    ad_script_abort
}


set config_files [list]
foreach line [split $content "\n"] {
    set line [string trim $line]
    if {"" == $line} { continue}
    if {[regexp {^\#} $line]} { continue}
    if {[regexp {cfg_file=(.*)} $line match config_file]} { lappend config_files $config_file }
}

ns_write "<h2>Config Files</h2>\n"
ns_write [join $config_files "<br>"]

# ------------------------------------------------------------
# Read and parse the object files
#

set lines [list]
foreach config_file $config_files {

    ns_write "<h3>Parsing file: $config_file</h3>\n"
    if {[catch {
	set fl [open $config_file]
	fconfigure $fl -encoding $encoding
	set content [read $fl]
	close $fl
    } err]} {
	ns_write "<li>Unable to open file $config_file:<br><pre>\n$err</pre>"
	ns_write [im_footer]
	ad_script_abort
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
	    command - timeperiod - contact - contactgroup - hostgroup - {
		# No action required.
	    }
	    host {
		# define host {use linux-server host_name storage02 alias {Storage 02} address 172.26.2.7}
		if {[catch {
		    set name "unknown"
		    if {[info exists def_hash(name)]} { set name $def_hash(name) }
		    if {[info exists def_hash(host_name)]} { set name $def_hash(host_name) }
		    set hosts_hash($name) [array get def_hash]
		    ns_write "<li>Found host=$name\n"
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
		    set host_name "unknown"
		    if {[info exists def_hash(host_name)]} { set host_name $def_hash(host_name) }
		    set service_description "unknown"
		    if {[info exists def_hash(service_description)]} { 
			set service_description $def_hash(service_description) 
		    }
		    set name "$host_name-$service_description"	    
		    set services_hash($name) [array get def_hash]
		    ns_write "<li>Found service=$name\n"
		} err_msg]} {
		    ns_write "<p class=error>
			Error parsing '$def_type' definition in file '$config_file':
			<pre>$err_msg</pre><br>[array get def_hash]</p>\n
		    "
		}
	    }
	    default {
		ns_write "<p class=error>Unknown definition '$def_type'</p>\n"
	    }
	}
    }

}


ns_write [im_footer]


