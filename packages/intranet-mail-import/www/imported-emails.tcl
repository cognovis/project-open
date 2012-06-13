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

set page_title "Users with Imported Mails"
set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]
set return_url [im_url_with_query]
set current_url_without_vars [ns_conn url]

# ------------------------------------------------------------------
# Successfully imported messages
# ------------------------------------------------------------------

list::create \
    -name successfull_stats \
    -multirow successfull_stats_multirow \
    -key stat_id \
    -row_pretty_plural "Successfully Imported Mails" \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {
    } -bulk_actions {
    } -elements {
        stat_count {
            display_col stat_count
            label "Imported Emails"
        }
        stat_email {
            display_col stat_email
            label "Email"
            link_url_eval $user_url
        }
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                stat_count {}
                stat_email {}
            }
        }
    }

db_multirow -extend { create_user_url user_url } successfull_stats_multirow successfull_mail_import_stats "
	select
		count(*) as stat_count,
		pa.party_id,
		im_email_from_user_id(pa.party_id) as stat_email
	from
		acs_rels ar,
		acs_mail_bodies amb,
		acs_objects ao,
		parties pa
	where
		ar.object_id_one = amb.body_id
		and amb.body_id = ao.object_id
		and ar.object_id_two = pa.party_id
	group by 
		pa.party_id
	order by
		stat_count DESC
" {
    set user_url [export_vars -base "/intranet/users/view" {{user_id $party_id}}]
    set create_user_url [export_vars -base "asdf" {email}]
}


ad_return_template

