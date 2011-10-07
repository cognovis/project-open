ad_page_contract {
    Delete the indicator
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2011-08-13
    @cvs-id $Id$
} {
    indicator_id:integer
    { return_url "/intranet-reporting-indicators/index" }
}

set current_user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$admin_p} { 
    ad_return_complaint 1 "You are not an Administrator"
    ad_script_abort
}

db_string del "select im_indicator__delete(:indicator_id)"
ad_returnredirect $return_url

