ad_page_contract {
    
    Asks whether users will be allowed to assign multiple
    categories of this subtree to objects and if users
    have to categorize an object in this subtree.

    Then assings this subtree to the passed object (usually a package_id).

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,notnull
    {category_id:integer,optional ""}
    {locale ""}
    object_id:integer,notnull
    {edit_p 0}
    ctx_id:integer,optional
}

set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

array set tree [category_tree::get_data $tree_id $locale]
set tree_name $tree(tree_name)
if {$tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

set context_bar [list [category::get_object_context $object_id] [list "[export_vars -no_empty -base object-map {locale object_id ctx_id}]" [_ categories.cadmin]] "Mapping Parameters"]

if {$edit_p} {
    # parameters are edited, so get old data
    db_1row get_mapped_subtree_id ""
}

if {$category_id eq ""} {
    set page_title "Parameters of mapping to tree \"$tree_name\""
} else {
    set category_name [category::get_name $category_id $locale]
    set page_title "Parameters of mapping to subtree \"$tree_name :: $category_name\""
}

ad_form -name tree_map_form -action tree-map-2 -export { tree_id category_id locale object_id edit_p ctx_id} -form {
    {widget:text(radio) {label "Widget"} {options {
	{"Select" select}
	{"Multiselect - let users assign multiple categories" multiselect}
	{"Radio" radio}
	{"Checkbox - let users assign multiple categories" checkbox}
    }}}
    {require_category_p:text(radio) {label "Require users to assign at least one category?"} {options {{"Yes" t} {"No" f}}}}
} -on_request {
    if {$edit_p} {
	db_1row get_mapping_parameters ""
	if { $widget eq "" } {
	    # this is pre-widget selection and we default to the same
	    # look and feel as before
	    if { $assign_single_p } {
		set widget "select"
	    } else {
		set widget "multiselect"
	    }
	}
    } else {
	# we default to the default before widgets could be selected
	set widget multiselect
	set require_category_p f
    }
} -on_submit {
    if { $widget eq "select" || $widget eq "radio" } {
	set assign_single_p t
    } else {
	set assign_single_p f
    }
    if {$edit_p} {
	category_tree::edit_mapping -tree_id $tree_id -object_id $object_id -assign_single_p $assign_single_p -require_category_p $require_category_p -widget $widget
    } else {
	category_tree::map -tree_id $tree_id -subtree_category_id $category_id -object_id $object_id -assign_single_p $assign_single_p -require_category_p $require_category_p -widget $widget
    }
} -after_submit {
    ad_returnredirect [export_vars -no_empty -base object-map {locale object_id ctx_id}]
    ad_script_abort
}

ad_return_template
