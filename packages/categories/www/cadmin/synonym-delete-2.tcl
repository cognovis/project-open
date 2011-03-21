ad_page_contract {

    Deletes a category synonym.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    synonym_id:integer,multiple
    category_id:integer,notnull
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

db_transaction {
    foreach synonym_id [db_list check_synonyms_for_delete ""] {
	category_synonym::delete $synonym_id
    }
} on_error {
    ad_return_complaint 1 {{Error deleting category synonym.}}
    return
}

ad_returnredirect [export_vars -no_empty -base synonyms-view {category_id tree_id locale object_id ctx_id}]
