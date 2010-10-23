ad_page_contract {

    Deletes a category from a category tree

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    category_id:integer,multiple
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

db_transaction {
    foreach category_id [db_list order_categories_for_delete ""] {
	category::delete $category_id
    }
    category_tree::flush_cache $tree_id
} on_error {
    ad_return_complaint 1 {{Error deleting category. A category probably still contains subcategories. If you really want to delete those subcategories, please delete them first. Thank you.}}
    return
}

ad_returnredirect [export_vars -no_empty -base tree-view {tree_id locale object_id ctx_id}]
