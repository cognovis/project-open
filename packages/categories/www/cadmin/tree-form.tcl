ad_page_contract {
    Form to add/edit a category tree.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,optional
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    context_bar:onevalue
    page_title:onevalue
}

auth::require_login

if { ![ad_form_new_p -key tree_id] } {
    set page_title "Edit tree"
} else {
    set page_title "Add tree"
}

if { [info exists object_id] } {
    set context_bar [list \
          [category::get_object_context $object_id] \
          [list [export_vars -no_empty -base object-map {locale ctx_id object_id}] \
          [_ categories.cadmin]]]
} else {
    set context_bar [list \
          [list ".?[export_vars -no_empty {locale ctx_id}]" \
          [_ categories.cadmin]]]
}
lappend context_bar $page_title
