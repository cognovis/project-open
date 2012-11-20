ad_page_contract {
    @author malte.sussdorff@cognovis.de
} {
}

set return_url "/intranet"
set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Resources CSV"
set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}
