ad_page_contract {
    Toggle the site-wide status of a category tree.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    action:integer
    {locale ""}
    object_id:integer,optional
}

set user_id [auth::require_login]
set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege category_admin

db_dml toggle_site_wide_status ""

ad_returnredirect [export_vars -no_empty -base permission-manage {tree_id locale object_id}]
