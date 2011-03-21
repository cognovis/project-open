ad_page_contract {

    Displays a simple view of the source category tree for copy.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    source_tree_id:integer
    target_tree_id:integer
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    tree:multirow
}

set user_id [auth::require_login]
set tree_id $source_tree_id

array set target_tree [category_tree::get_data $target_tree_id $locale]
set target_tree_name $target_tree(tree_name)

if {$target_tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

set tree_name [category_tree::get_name $tree_id $locale]
set page_title "Category Tree \"$tree_name\""

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar [list [export_vars -no_empty -base tree-copy { {tree_id $target_tree_id} locale object_id ctx_id }] "Copy tree"] "View \"$tree_name\""

template::multirow create tree category_name deprecated_p level left_indent

foreach category [category_tree::get_tree -all $tree_id $locale] {
    util_unlist $category category_id category_name deprecated_p level

    template::multirow append tree $category_name $deprecated_p $level [string repeat "&nbsp;" [expr ($level-1)*5]]
}

template::list::create \
    -name tree \
    -no_data "None" \
    -elements {
	category_name {
	    label "Name"
	    display_template {
		@tree.left_indent;noquote@ @tree.category_name@
	    }
	}
    }

ad_return_template
