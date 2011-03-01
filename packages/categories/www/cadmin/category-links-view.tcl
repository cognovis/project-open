ad_page_contract {

    Display all linked categories for a category

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    category_id:integer,notnull
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
    orderby:optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    category_links:multirow
}

set user_id [auth::require_login]
permission::require_permission -object_id $tree_id -privilege category_tree_write

set tree_name [category_tree::get_name $tree_id $locale]
set category_name [category::get_name $category_id $locale]
set page_title "Categories linked with category \"$tree_name :: $category_name\""

set context_bar [category::context_bar $tree_id $locale \
                     [value_if_exists object_id] \
                     [value_if_exists ctx_id]]
lappend context_bar "Links to $category_name"


#----------------------------------------------------------------------
# List builder
#----------------------------------------------------------------------

template::list::create \
    -name category_links \
    -no_data "None" \
    -key link_id \
    -has_checkboxes \
    -orderby {
	default_value link_name,asc
	link_name {
	    label link_name
	    multirow_cols {tree_name category_name direction}
	}
	direction {
	    label direction
	    multirow_cols {direction tree_name category_name}
	}
    } -filters {
	category_id {}
	tree_id {}
	locale {}
	object_id {}
	ctx_id {}
    } -actions [list \
		  "Add link" [export_vars -no_empty -base category-link-add { category_id tree_id locale object_id ctx_id}] "Add new category link"] \
    -bulk_actions {
	"Delete" "category-link-delete" "Delete checked category links"
    } -bulk_action_export_vars { category_id tree_id locale object_id ctx_id} \
    -elements {
	checkbox {
	    display_template {
		<if @category_links.write_p@ eq t><input type="checkbox" name="link_id" value="@category_links.link_id@" id="category_links,@category_links.link_id@" title="Check/uncheck this row, and select an action to perform below"></if>
	    }
	}
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
	delete {
	    sub_class narrow
	    display_template {
		<img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" alt="Delete" style="border:0">
	    }
	    link_url_col delete_url
	    link_html { title "Delete link" }
	}
    }

db_multirow category_links get_category_links ""

multirow extend category_links delete_url tree_view_url category_view_url tree_name category_name
multirow foreach category_links {
    set delete_url [export_vars -no_empty -base category-link-delete { link_id category_id tree_id locale object_id ctx_id}]
    set tree_view_url [export_vars -no_empty -base tree-view { {tree_id $linked_tree_id} locale object_id ctx_id}]
    set category_view_url [export_vars -no_empty -base category-links-view { {category_id $linked_category_id} {tree_id $linked_tree_id} locale object_id ctx_id}]

    set tree_name [category_tree::get_name $linked_tree_id $locale]
    set category_name [category::get_name $linked_category_id $locale]
}

ad_return_template
