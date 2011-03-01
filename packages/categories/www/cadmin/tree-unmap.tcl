ad_page_contract {

    Unmapping a category tree from an object.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,notnull
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    tree_name:onevalue
    object_name:onevalue
    form_vars:onevalue
    cancel_form_vars:onevalue
}
 
set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

array set tree [category_tree::get_data $tree_id $locale]
if {$tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

set page_title "Unmap tree"

set delete_url [export_vars -no_empty -base tree-unmap-2 { tree_id locale object_id ctx_id}]
set cancel_url [export_vars -no_empty -base object-map { locale object_id ctx_id}]

set object_context [category::get_object_context $object_id]
set object_name [lindex $object_context 1]
set tree_name $tree(tree_name)

set context_bar [list $object_context [list [export_vars -no_empty -base object-map {locale object_id ctx_id}] [_ categories.cadmin]] "Unmap \"$tree_name\""]

ad_return_template
