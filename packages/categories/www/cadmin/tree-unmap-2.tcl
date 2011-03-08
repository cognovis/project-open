ad_page_contract {

    Unmapping a category tree from an object.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,notnull
    ctx_id:integer,optional
} 

set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

array set tree [category_tree::get_data $tree_id $locale]
if {$tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

category_tree::unmap -tree_id $tree_id -object_id $object_id

ad_returnredirect [export_vars -no_empty -base object-map {locale object_id ctx_id}]
