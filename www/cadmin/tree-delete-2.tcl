ad_page_contract {

    This page checks whether the category tree can be deleted and deletes it.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
}

set user_id [ad_maybe_redirect_for_registration]
permission::require_permission -object_id $tree_id -privilege category_tree_write

set instance_list [category_tree::usage $tree_id]

if {[llength $instance_list] > 0} {
    ad_return_complaint 1 {{This category tree is still in use.}}
    return
}

category_tree::delete $tree_id

if {![info exists object_id]} {
    ad_returnredirect ".?[export_vars -no_empty {locale}]"
} else {
    ad_returnredirect [export_vars -no_empty -base object-map {locale object_id}]
}
