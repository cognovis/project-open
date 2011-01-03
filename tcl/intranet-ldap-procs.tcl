# /packages/intranet-sysconfig/tcl/intranet-ldap-procs.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    SysConfig LDAP Wizard Library
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------
# Connect to LDAP server
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_check_port_open { 
    -ldap_ip_address:required
    -ldap_port:required
} {
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "open" contains "1" if the port @ ip is open of "0" otherwise.
    The key "debug" contains additional text lines from the Perl script
    suitable to be displayed using a "pre" HTML tag.
} {
    array set hash {}
    
    set port_open_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/ldap-check-port.perl"
    set cmd "perl $port_open_perl $ldap_ip_address $ldap_port"
    ns_log Notice "im_sysconfig_ldap_check_port_open: $cmd"

    set debug ""
    if {[catch {
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	set debug ""
	while {[gets $fp line] >= 0} {
	    append debug "$line\n"
	}
	close $fp
    } err_msg]} {
	set open_p 0
    } else {
	set open_p 1
    }

    set hash(open_p) $open_p
    set hash(debug) $debug

    return [array get hash]
}



# ---------------------------------------------------------------
# Connect to LDAP server
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_check_bind { 
    -ldap_ip_address:required
    -ldap_port:required
    -ldap_type:required
    -ldap_binddn:required
    -ldap_bindpw:required
} {
    Tries to bind to the LDAP server using the selected binddn/bindpw (username/password).
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "success" contains "1" if the bind was successfull and "0" otherwise.
    The key "debug" contains additional text lines from the Perl script
    suitable to be displayed using a "pre" HTML tag.
} {
    array set hash {}
    
    set bind_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/ldap-check-bind.perl"
    set cmd "perl $bind_perl $ldap_ip_address $ldap_port $ldap_type $ldap_binddn $ldap_bindpw"
    ns_log Notice "im_sysconfig_ldap_check_bind: $cmd"

    set debug ""
    if {[catch {
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	set debug ""
	while {[gets $fp line] >= 0} {
	    append debug "$line\n"
	}
	close $fp
    } err_msg]} {
	# We get here after the Perl script performs an "exit 1"
	set success_p 0
	append debug $err_msg
    } else {
	set success_p 1
    }

    set hash(success_p) $success_p
    set hash(debug) $debug

    return [array get hash]
}



# ---------------------------------------------------------------
# Get information about LDAP objects
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_get_info { 
    -ldap_ip_address:required
    -ldap_port:required
} {
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "result" contains "1" for a successful LDAP connect or "0" for a 
    failed one.
} {
    array set hash {}
    
    set connect_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/connect.perl"
    set cmd "perl $connect_perl"
    set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]

    set debug ""
    while {[gets $fp line] >= 0} {
	append debug $line
	append debug "<br>\n"
    }
    close $fp

    set hash(result) 1
    set hash(debug) $debug

    return [array get hash]
}
