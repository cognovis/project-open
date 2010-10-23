ad_page_contract {
    Reactivates deprecated categories.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    category_id:integer,multiple
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
}

permission::require_permission -object_id $tree_id -privilege category_tree_write

db_transaction {
    foreach id $category_id {
	category::phase_in $id
    }
}
category_tree::flush_cache $tree_id

ad_returnredirect [export_vars -no_empty -base tree-view { tree_id locale object_id ctx_id}]
