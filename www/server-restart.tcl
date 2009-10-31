ad_page_contract {

    Kill (restart) the server.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 27:th of March 2003
    @cvs-id $Id$
}

set page_title "Restarting Server"
set context [list $page_title]
set po "&#93;project-open&#91;"

# Check for Windows platform
global tcl_platform
set windows_p [string match $tcl_platform(platform) "windows"]

# We do this as a schedule proc, so the server will have time to serve the page
#ad_schedule_proc -thread t -once t 2 ns_shutdown
