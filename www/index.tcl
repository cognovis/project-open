ad_page_contract {

} {

}

set user_id [ad_maybe_redirect_for_registration]

set content [im_workflow_home_component]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set admin_html ""
if {$user_is_admin_p} {
    set admin_html "<li><a href=\"/workflow/admin/\">#intranet-workflow.Admin_workflows#</a>\n"
#    append admin_html "<li><a href=\"/workflow/admin/cases?state=active\">[lang::message::lookup "" intranet-workflow.Debug_Workflows "Debug Workflows"]</a>\n"
}