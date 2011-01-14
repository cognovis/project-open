ad_page_contract {
    Generates a GIF image displaying the workflow
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 22 August 2000
    @cvs-id $Id$
} {
    tmpfile:notnull
}

# fraber 110114: There can be several GIFs per page,
# so checking for a single client_property doesn't work.
#
set ttt {
 -validate {
    tmpfile_valid -requires { tmpfile:notnull } {
	if { ![string equal $tmpfile [ad_get_client_property wf wf_net_tmpfile]] } {
	    ad_complain "Bad tmpfile argument"
	}
    }
}
}

# Make sure the tmpfile starts off with tmp_path
set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow'}]
set tmp_path [ad_parameter -package_id $package_id "tmp_path"]
if {[string first $tmp_path $tmpfile] != 0} {
    ad_return_complaint 1 "Invalid argument: tmpfile='$tmpfile'"
    ad_script_abort
}


global tcl_platform
if {[string match $tcl_platform(platform) "windows"]} {

    set winaoldir $::env(AOLDIR)
    set unixaoldir [string map {\\ /} ${winaoldir}]
    set tmpfile ${winaoldir}/${tmpfile}

}


ns_returnfile 200 image/gif $tmpfile
file delete $tmpfile
    


