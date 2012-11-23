# /packages/intranet-reste/www/version.tcl
#
# Copyright (C) 2010 ]project-open[
#

# ---------------------------------------------------------
# Returns a version string.
# Changes in the major number of the version 
# indicate incompatibilites, while changes in
# the minor number mean upgrades.
#
# Please see www.project-open.org/en/rest_version_history


set version [im_rest_version]


if {![info exists format]} { set format "html" }
if {![info exists user_id]} { set user_id 0 }
set rest_url "[im_rest_system_url]/intranet-rest"

if {0 == $user_id} {
    # User not autenticated
    switch $format {
	html {
	    ad_return_complaint 1 "Not authorized"
	    ad_script_abort
	}
	xml {
	    im_rest_error -http_status 401 -message "Not authenticated"
	    return
	}
    }
}

# Got a user already authenticated by Basic HTTP auth or auto-login
switch $format {
    xml {
	set xml_p 1
	set xml "<?xml version='1.0' encoding='UTF-8'?>\n<version>\n$version</version>\n"
    }
    default {
	set xml_p 0
	set page_title [lang::message::lookup "" intranet-rest "REST Version"]
	set context_bar ""
    }
}
	