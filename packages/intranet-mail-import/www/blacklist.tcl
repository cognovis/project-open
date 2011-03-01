# /packages/intranet-mail-import/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author frank.bergmann@project-open.com
    @creation-date Nov 2003
} {
    { return_url "" }
    { bread_crum_path "" }
    {orderby "name"}
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

set page_title "Blacklist"
set context_bar [im_context_bar [list /intranet-mail-import/ "Mail Import"] $page_title]
set current_url_without_vars [ns_conn url]
if {"" == $return_url} { set return_url [im_url_with_query] }


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name blacklist \
    -multirow blacklist_multirow \
    -key blacklist_id \
    -row_pretty_plural "Blacklist" \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -bulk_actions { 
	"Remove" "blacklist-remove" "Remove item from Blacklist"
    } \
    -bulk_action_method POST \
    -bulk_action_export_vars { return_url } \
    -elements {
        blacklist_email {
            label "Email"
        }
    }

db_multirow -extend { create_user_url } blacklist_multirow mail_import_stats "
	select	*
	from	im_mail_import_blacklist
	order by
		blacklist_email
" {
    set create_user_url [export_vars -base "asdf" {email}]
}


ad_return_template

