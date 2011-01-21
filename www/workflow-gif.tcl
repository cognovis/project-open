
# fraber 110118: Don't use ad_page_contact, 
# because it somehow doesn't allow tmpfile to take the
# value C:/project-open/projop/tmp/...

# ad_page_contract {
#     Generates a GIF image displaying the workflow
#     
#     @author Lars Pind (lars@pinds.com)
#     @creation-date 22 August 2000
#     @cvs-id $Id$
# } {
#     { tmpfile:allhtml "" }
# } -validate {
#    tmpfile_valid -requires { tmpfile:notnull } {
#	if { ![string equal $tmpfile [ad_get_client_property wf wf_net_tmpfile]] } {
#	    ad_complain "Bad tmpfile argument"
#	}
#   }
# }

# Instead of ad_page_contract, we manually parse the HTTP header
set query [ns_conn query]
set query_vars [ns_parsequery $query]
set tmpfile [ns_set get $query_vars "tmpfile"]

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

if {![file exists $tmpfile]} { ad_return_complaint 1 "file '$tmpfile' doesn't exist" }


if {[file exists $tmpfile]} { 
    ns_returnfile 200 image/gif $tmpfile 
    file delete $tmpfile
}

ns_returnfile 200 image/gif "[acs_root_dir]/packages/intranet-core/www/images/navbar_default/computer_error.png"
