# /packages/intranet-translation/www/trans-tasks/task-save.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Takes commands from the /intranet/projects/view
    page and saves changes, deletes tasks and scans for Trados
    files.

    @param return_url the url to return to
    @param project_id
} {
    { return_url "" }
    blacklist_id:multiple
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [im_url_with_query] }

foreach id $blacklist_id {

    db_dml blacklist "
	delete from im_mail_import_blacklist
	where blacklist_id = :blacklist_id
    "

}

ad_returnredirect $return_url


