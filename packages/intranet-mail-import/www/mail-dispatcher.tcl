# /packages/intranet-mail-import/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author klaus.hofeditz@project-open.com
    @creation-date April 2012
} {
    { bread_crum_path "" }
    { orderby "name" }
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

set page_title  [lang::message::lookup "" intranet-mail-import.Mail_Assignment_title "Assign mails to users or projects"]
set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]
set return_url [im_url_with_query]
set current_url_without_vars [ns_conn url]

# src="/intranet-sencha/js/ext-all.js" 
template::head::add_javascript -src "/intranet-sencha/js/ext-all-debug-w-comments.js" -order "100"
template::head::add_javascript -src "/intranet-mail-import/js/ext-app-mail-assignment.js" -order "130"
template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order "120"
