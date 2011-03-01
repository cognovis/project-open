# /packages/intranet-reporting-tutorial/www/projects-01.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.


ad_page_contract {
    Show the source code of a report
    @author frank.bergmann@projec-open.com
} {
    { return_url "" }
    { source "projects-01-commented" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Everybody can see the source code of these tutorials, 
# so we don't need more security checks here.

set error 0
set message "undefined"
if {![regexp {^[0-9a-zA-Z_\-]+$} $source match]} { 
    set error 1 
    set message "Report name containing invalid characers"
}

set source_file "[acs_root_dir]/packages/intranet-reporting-tutorial/www/${source}.tcl"

if {!$error && ![file exists $source_file]} {
    set error 1
    set message "Report doesn't exist"
}

set content ""
if {[catch {
    set fl [open $source_file]
    set content [read $fl]
    close $fl
} err]} {
    if {!$error} {
	set error 1
	set message "Unable to open report source file"
    }
}

if {$error} {
    im_security_alert \
	-location "/intranet-reporting-tutorial/www/source.tcl" \
	-message $message \
	-value $source 
    ad_return_complaint 1 "<b>$message</b>:<br><pre>$source</pre>"
    ad_page_abort
}

doc_return 200 "text/html" "
[im_header]
[im_navbar]
<pre>[ns_quotehtml $content]</pre>
[im_footer]
"


