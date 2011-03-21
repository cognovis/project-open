ad_page_contract {

    Ask for confirmation to delete category links

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    link_id:integer,multiple
    category_id:integer
    tree_id:integer
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    delete_url:onevalue
    cancel_url:onevalue
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

set tree_name [category_tree::get_name $tree_id $locale]
set category_name [category::get_name $category_id $locale]

set allowed_link_ids [list]
set page_title "Delete links with category \"$tree_name :: $category_name\""

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar \
    [list [export_vars -no_empty -base category-links-view {category_id tree_id locale object_id  ctx_id}] "Links to $category_name"] \
    "Delete Links"

multirow create category_links linked_category_id linked_tree_id direction

db_foreach check_category_links "" {
    if {$write_p == "t"} {
	multirow append category_links $linked_category_id $linked_tree_id $direction
	lappend allowed_link_ids $link_id
    }
}

multirow extend category_links tree_view_url category_view_url tree_name category_name
multirow foreach category_links {
    set tree_view_url [export_vars -no_empty -base tree-view { {tree_id $linked_tree_id} locale object_id  ctx_id}]
    set category_view_url [export_vars -no_empty -base category-links-view { {category_id $linked_category_id} {tree_id $linked_tree_id} locale object_id  ctx_id}]

    set tree_name [category_tree::get_name $linked_tree_id $locale]
    set category_name [category::get_name $linked_category_id $locale]
}

multirow sort category_links -dictionary tree_name category_name direction

set delete_url [export_vars -no_empty -base category-link-delete-2 { {link_id:multiple $allowed_link_ids} category_id tree_id locale object_id  ctx_id}]
set cancel_url [export_vars -no_empty -base category-links-view { category_id tree_id locale object_id  ctx_id}]

template::list::create \
    -name category_links \
    -no_data "None" \
    -elements {
	direction {
	    sub_class narrow
	    label "Direction"
	    display_template {
		<if @category_links.direction@ eq f><img src="/resources/acs-subsite/right.gif" height="16" width="16" alt="forward link" style="border:0"></if>
		<else><img src="/resources/acs-subsite/left.gif" height="16" width="16" alt="backward link" style="border:0"></else>
	    }
	    html {align center}
	}
	link_name {
	    label "Linked category"
	    display_template {
		<a href="@category_links.tree_view_url@" title="View this tree">@category_links.tree_name@</a>
		:: <a href="@category_links.category_view_url@" title="View links of this category">@category_links.category_name@</a>
	    }
	}
    }

ad_return_template 
