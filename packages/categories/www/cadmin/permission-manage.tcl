ad_page_contract {
    Let the user toggle the site-wide status of a category tree.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    object_id:integer,optional
    {locale ""}
} -properties {
    page_title:onevalue
    context_bar:onevalue
    sw_tree_p:onevalue
    admin_p:onevalue
    url_vars:onevalue
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_grant_permissions

array set tree [category_tree::get_data $tree_id $locale]
set tree_name $tree(tree_name)
set page_title "Permission Management for $tree_name"

set context_bar [category::context_bar $tree_id $locale [value_if_exists object_id]]
lappend context_bar "Manage Permissions"

set url_vars [export_vars {tree_id object_id locale}]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id -privilege category_admin]
set sw_tree_p [ad_decode $tree(site_wide_p) f 0 1]

ad_return_template
