if {![info exists ctx_id]} {
  set package_id [ad_conn package_id]
} else {
  set package_id $ctx_id
}

set languages [lang::system::get_locale_options]

ad_form -name tree_form \
    -mode [ad_decode [ad_form_new_p -key tree_id] 1 edit display] \
    -action tree-form \
    -export { locale object_id ctx_id } \
    -form {
    {tree_id:key}
    {tree_name:text {label "Name"} {html {size 50 maxlength 50}}}
    {language:text(select) {label "Language"} {options $languages}}
    {description:text(textarea),optional {label "Description"} {html {rows 5 cols 80}}}
} -new_request {
    permission::require_permission -object_id $package_id -privilege category_admin
    set language $locale
} -edit_request {
    permission::require_permission -object_id $tree_id -privilege category_tree_write
    set action Edit
    util_unlist [category_tree::get_translation $tree_id $locale] tree_name description
    set language $locale
} -on_submit {
    set description [util_close_html_tags $description 4000]
} -new_data {
    db_transaction {
	category_tree::add -tree_id $tree_id -name $tree_name -description $description -locale $language -context_id $package_id
	if { [info exists object_id] } {
	    category_tree::map -tree_id $tree_id -object_id $object_id
	    set return_url [export_vars -base object-map { locale object_id ctx_id}]
	} else {
	    set return_url [export_vars -base tree-view { tree_id locale ctx_id}]
	}
    }
} -edit_data {
    category_tree::update -tree_id $tree_id -name $tree_name -description $description -locale $language
    set return_url [export_vars -base tree-view { tree_id locale object_id ctx_id}]
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
}

