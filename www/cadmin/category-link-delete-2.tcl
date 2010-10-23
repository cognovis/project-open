ad_page_contract {

    Deletes category links

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    link_id:integer,multiple
    category_id:integer
    tree_id:integer
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

db_transaction {
    foreach link_id [db_list check_category_link_permissions ""] {
	category_link::delete $link_id
    }
} on_error {
    ad_return_complaint 1 {{Error deleting category link.}}
    return
}

ad_returnredirect [export_vars -no_empty -base category-links-view {category_id tree_id locale object_id ctx_id}]
