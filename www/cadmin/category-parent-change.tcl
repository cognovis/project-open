ad_page_contract {
    
    Changes the parent category of a category.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    category_id:integer
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
permission::require_permission -object_id $tree_id -privilege category_tree_write

set category_name [category::get_name $category_id $locale]
set page_title "Change parent category of \"$category_name\""
set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar "Change parent"


set subtree_categories_list [db_list get_subtree ""]

template::multirow create tree category_name category_id deprecated_p level left_indent parent_url
template::multirow append tree "Root Level" 0 f 0 "" \
    [export_vars -no_empty -base category-parent-change-2 {tree_id category_id locale object_id ctx_id}]

foreach category [category_tree::get_tree -all $tree_id $locale] {
    util_unlist $category parent_id category_name deprecated_p level

    if { [lsearch $subtree_categories_list $parent_id]==-1 } {
	set parent_url [export_vars -no_empty -base category-parent-change-2 { parent_id tree_id category_id locale object_id ctx_id }]
    } else {
	set parent_url ""
    }
    template::multirow append tree $category_name $category_id $deprecated_p $level [string repeat "&nbsp;" [expr ($level-1)*5]] $parent_url
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
	set_parent {
	    label "Action"
	    display_template {
		<if @tree.parent_url@ not nil><a href="@tree.parent_url@">Set parent</a></if>
	    }
	}
    }

ad_return_template
