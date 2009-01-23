ad_page_contract {

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
}

set page_title "DynField Extensible Architecture"
set context_bar [im_context_bar $page_title]

set package_id [apm_package_id_from_key "intranet-dynfield"]
set param_url [export_vars -base "/shared/parameters" -url {package_id {return_url "/intranet-dynfield"}}]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

ad_return_template
