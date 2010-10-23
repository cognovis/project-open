ad_page_contract {
    
    Let user decide about the target category to add a category link.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    link_tree_id:integer,notnull
    category_id:integer,notnull
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    trees:multirow
}

set user_id [auth::require_login]

permission::require_permission -object_id $tree_id -privilege category_tree_write
permission::require_permission -object_id $link_tree_id -privilege category_tree_write

set category_name [category::get_name $category_id $locale]
set tree_name [category_tree::get_name $tree_id $locale]
set link_tree_name [category_tree::get_name $link_tree_id $locale]
set page_title "Add link from \"$link_tree_name\" to category \"$tree_name :: $category_name\""

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar \
    [list [export_vars -no_empty -base category-links-view {category_id tree_id locale object_id ctx_id}] "Links to $category_name"] \
    [list [export_vars -no_empty -base category-link-add {category_id tree_id locale object_id ctx_id}] "Select link target"] \
    "Add link"


db_foreach get_linked_categories "" {
    if {$direction == "f"} {
	set forward_links($linked_category_id) 1
    } else {
	set backward_links($linked_category_id) 1
    }
}

template::multirow create tree link_category_name link_category_id forward_exists_p backward_exists_p left_indent view_url link_add_url bilink_add_url

foreach category [category_tree::get_tree -all $link_tree_id $locale] {
    util_unlist $category link_category_id link_category_name deprecated_p level
    set forward_exists_p [info exists forward_links($link_category_id)]
    set backward_exists_p [info exists backward_links($link_category_id)]

    template::multirow append tree $link_category_name $link_category_id $forward_exists_p $backward_exists_p \
	[string repeat "&nbsp;" [expr ($level-1)*5]] \
	[export_vars -no_empty -base category-links-view {{category_id $link_category_id} {tree_id $link_tree_id} locale object_id  ctx_id}] \
	[export_vars -no_empty -base category-link-add-3 {link_category_id category_id tree_id locale object_id ctx_id}] \
	[export_vars -no_empty -base category-link-add-4 {link_category_id category_id tree_id locale object_id ctx_id}]
    }

template::list::create \
    -name tree \
    -no_data "None" \
    -key link_category_id \
    -bulk_actions {
	"Add links" "category-link-add-3" "Add category links to checked categories"
	"Add bidirectional links" "category-link-add-4" "Add bidirectional category links to checked categories"
    } -bulk_action_export_vars { category_id tree_id locale object_id ctx_id} \
    -elements {
	links {
	    sub_class narrow
	    display_template {
		<if @tree.backward_exists_p@ true><img src="/resources/acs-subsite/left.gif" height="16" width="16" alt="backward link" style="border:0"></if>
		<if @tree.forward_exists_p@ true><img src="/resources/acs-subsite/right.gif" height="16" width="16" alt="forward link" style="border:0"></if>
	    }
	    html {align center}
	}
	name {
	    label "Name"
	    display_template {
		@tree.left_indent;noquote@ <a href="@tree.view_url@">@tree.link_category_name@</a>
	    }
	}
	actions {
	    label "Actions"
	    display_template "
		<if @tree.link_category_id@ ne $category_id>
		  <a href=\"@tree.link_add_url@\">Add link</a> &nbsp; &nbsp;
		  <a href=\"@tree.bilink_add_url@\">Add bidirectional link</a>
		</if>
	    "
	}
    }

ad_return_template
