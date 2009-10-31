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

global tcl_platform
if {[string match $tcl_platform(platform) "windows"]} {

    set winaoldir $::env(AOLDIR)
    set unixaoldir [string map {\\ /} ${winaoldir}]
    set tmpfile ${winaoldir}/${tmpfile}

}


ns_returnfile 200 image/gif $tmpfile
file delete $tmpfile
    


