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
    return_url
    stat_email:multiple
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

foreach email $stat_email {

    db_dml blacklist "
	insert into im_mail_import_blacklist (
		blacklist_id,
		blacklist_email,
		blacklist_day
	) values (
		nextval('im_mail_import_blacklist_seq'),
		:email,
		now()
	)
    "

}

ad_returnredirect $return_url


