ad_page_contract {

    Let the user select a category tree which will be copied into the current category tree

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    trees:multirow
    tree_id:onevalue
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

set tree_name [category_tree::get_name $tree_id $locale]
set target_tree_id $tree_id
set page_title "Copy a tree into \"$tree_name\""

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar "Copy tree"

template::multirow create trees tree_id tree_name site_wide_p view_url copy_url

db_foreach trees_select "" {
    if {$site_wide_p == "t" || $has_read_p == "t"} {
	set source_tree_name [category_tree::get_name $source_tree_id $locale]

	template::multirow append trees $source_tree_id $source_tree_name $site_wide_p \
	[export_vars -no_empty -base tree-copy-view { source_tree_id target_tree_id locale object_id ctx_id }] \
	[export_vars -no_empty -base tree-copy-2 { source_tree_id target_tree_id locale object_id ctx_id }]
    }
}

template::multirow sort trees -dictionary tree_name

template::list::create \
    -name trees \
    -no_data "None" \
    -elements {
	tree_name {
	    label "Name"
	    link_url_col view_url
	}
	site_wide_p {
	    display_template {
		<if @trees.site_wide_p@ eq t> (Site-Wide Tree) </if>
	    }
	}
	copy {
	    label "Action"
	    display_template {
		<a href="@trees.copy_url@">Copy tree</a>
	    }
	}
    }

ad_return_template
