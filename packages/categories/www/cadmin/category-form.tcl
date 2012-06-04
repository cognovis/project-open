ad_page_contract {
    Form to add/edit a category.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    category_id:integer,optional
    {parent_id:integer,optional [db_null]}
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    context_bar:onevalue
    page_title:onevalue
}

set user_id [auth::require_login]
set package_id [ad_conn package_id]
permission::require_permission -object_id $tree_id -privilege category_tree_write

if {[info exists category_id]} {
    set page_title "Edit category"
} else {
    set page_title "Add category"
}

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar $page_title

set languages [lang::system::get_locale_options]

ad_form -name category_form -action category-form \
  -export { tree_id parent_id locale object_id ctx_id } \
  -form {
    {category_id:key}
    {name:text {label "Name"} {html {size 50 maxlength 200}}}
    {language:text(select) {label "Language"} {value $locale} {options $languages}}
    {description:text(textarea),optional {label "Description"} {html {rows 5 cols 80}}}
} -new_request {
    set name ""
    set description ""
} -edit_request {
    if {![db_0or1row check_translation_existance ""]} {
	set default_locale [parameter::get -parameter DefaultLocale -default en_US]
	db_1row get_default_translation ""
    }
} -on_submit {
    set description [util_close_html_tags $description 4000]
} -new_data {
    category::add -category_id $category_id -tree_id $tree_id -parent_id $parent_id -locale $language -name $name -description $description
} -edit_data {
    category::update -category_id $category_id -locale $language -name $name -description $description
} -after_submit {
    ad_returnredirect [export_vars -no_empty -base tree-view {tree_id locale object_id ctx_id}]
    ad_script_abort
}

ad_return_template
