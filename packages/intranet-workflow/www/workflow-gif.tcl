ad_page_contract {
    Generates a GIF image displaying the workflow
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 22 August 2000
    @cvs-id $Id$
} {
    tmpfile:notnull
} -validate {
    tmpfile_valid -requires { tmpfile:notnull } {
	if { ![string equal $tmpfile [ad_get_client_property wf wf_net_tmpfile]] } {
	    ad_complain "Bad tmpfile argument"
	}
    }
}


# Find out if platform is "unix" or "windows"
global tcl_platform
set platform [lindex $tcl_platform(platform) 0]

switch $platform {
    windows {
	set winaoldir $::env(AOLDIR)
	set unixaoldir [string map {\\ /} ${winaoldir}]
	set tmpfile ${winaoldir}/${tmpfile}
	ns_returnfile 200 image/gif $tmpfile
	file delete $tmpfile
    }
    default {
	ns_returnfile 200 image/gif $tmpfile
	file delete $tmpfile
    }
}
