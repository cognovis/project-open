# /www/intranet/trans-tasks/task-list.tcl

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {

}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set user_is_employee_p [im_user_is_employee_p $current_user_id]


set return_url [im_url_with_query]

set page_title "Project Tasks"
set context_bar "hola"

set user_id "638"
set freelance_view_name "user_view_freelance"


set page_body "
hola
[im_freelance_info_component $current_user_id $user_id $user_is_admin_p "" $freelance_view_name]

[im_freelance_skill_component $current_user_id $user_id $user_is_admin_p return_url]
<br>

[im_freelance_member_select_component 644 "" ""]
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]

