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

set page_title "Missing Emails"
set context_bar [im_context_bar [list /intranet-mail-import/ "Mail Import"] $page_title]
set return_url [im_url_with_query]
set current_url_without_vars [ns_conn url]


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name missing_stats \
    -multirow missing_stats_multirow \
    -key stat_email \
    -row_pretty_plural "Mail Import Stats" \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -bulk_actions { 
	"Blacklist" "blacklist-action" "Blacklist this item"
    } \
    -bulk_action_method POST \
    -bulk_action_export_vars { return_url } \
    -elements {
        stat_count {
            display_col stat_count
            label "Miss Count"
        }
        stat_email {
            display_col stat_email
            label "Email"
        }
    }

db_multirow -extend { create_user_url } missing_stats_multirow mail_import_stats "
	select
		count(*) as stat_count,
		stat_email
	from
		im_mail_import_email_stats s
	where
		stat_email not in (
			select	email
			from	parties
			where	party_id in (
					select member_id from group_distinct_member_map
					where group_id = [im_employee_group_id]
				)
		    UNION
			select	lower(note)
			from	im_notes
			where	object_id in (
				select member_id from group_distinct_member_map
				where group_id = [im_employee_group_id]
			)
		   UNION
			select	blacklist_email
			from	im_mail_import_blacklist
		)
	group by 
		stat_email
	order by
		stat_count DESC
" {
    set create_user_url [export_vars -base "asdf" {email}]
}


ad_return_template

