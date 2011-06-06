# /packages/intranet-filestorage/tcl/intranet-filestorage-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Sencha Ticket Tracker Library
    @author frank.bergmann@project-open.com
}

ad_register_proc GET /intranet-sencha-ticket-tracker/* im_sencha_ticket_tracker_page


# Serve the abstract URL 
# /intranet/download/<group_id>/...
#
proc im_sencha_ticket_tracker_page { } {

    set user_id [ad_maybe_redirect_for_registration]

    # get the filename
    set url [ns_conn url]
    set path_list [split $url {/}]
    set file_name [lindex $path_list end]

    set path "[acs_root_dir]/packages/intranet-sencha-ticket-tracker/www/$file_name"
    ns_log Notice "im_sencha_ticket_tracker_page: url=$url, file_name=$file_name, path=$path"

    doc_return 200 "text/plain" $path

}

