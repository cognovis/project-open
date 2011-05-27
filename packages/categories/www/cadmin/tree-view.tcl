ad_page_contract {

    Display a category tree

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
} -properties {
    page_title:onevalue
    tree_name:onevalue
    tree_description:onevalue
    context_bar:onevalue
    locale:onevalue
    one_tree:multirow
    can_grant_p:onevalue
    can_write_p:onevalue
}

set user_id [auth::require_login]

array set tree [category_tree::get_data $tree_id $locale]
if {$tree(site_wide_p) == "f"} {
    permission::require_permission -object_id $tree_id -privilege category_tree_read
}

set tree_name $tree(tree_name)
set tree_description $tree(description)

set page_title [_ categories.Tree_view_title]
if {[info exists object_id]} {
    set context_bar [list [category::get_object_context $object_id] [list [export_vars -no_empty -base object-map {locale object_id ctx_id}] "[_ categories.cadmin]"] $tree_name]
} else {
    set context_bar [list [list ".?[export_vars -no_empty {locale ctx_id}]" "[_ categories.cadmin]"] $tree_name]
}

set can_write_p [permission::permission_p -object_id $tree_id -privilege category_tree_write]
set can_grant_p [permission::permission_p -object_id $tree_id -privilege category_tree_grant_permissions]

template::multirow create one_tree category_name sort_key category_id deprecated_p level left_indent

set sort_key 0

foreach category [category_tree::get_tree -all $tree_id $locale] {
    util_unlist $category category_id category_name deprecated_p level
    incr sort_key 10

    template::multirow append one_tree $category_name $sort_key $category_id $deprecated_p $level [string repeat "&nbsp;" [expr {($level-1)*5}]]
}



#----------------------------------------------------------------------
# List builder
#----------------------------------------------------------------------

multirow extend one_tree usage_url add_url edit_url delete_url parent_url phase_in_url phase_out_url links_view_url synonyms_view_url
multirow foreach one_tree {
    set usage_url [export_vars -no_empty -base category-usage { category_id tree_id locale object_id ctx_id}]
    if { $can_write_p } {
	set add_url [export_vars -no_empty -base category-form { { parent_id $category_id} tree_id locale object_id ctx_id}]
	set edit_url [export_vars -no_empty -base category-form { category_id tree_id locale object_id ctx_id}]
	set delete_url [export_vars -no_empty -base category-delete { category_id tree_id locale object_id ctx_id}]
	set parent_url [export_vars -no_empty -base category-parent-change { category_id tree_id locale object_id ctx_id}]
	set links_view_url [export_vars -no_empty -base category-links-view { category_id tree_id locale object_id ctx_id}]
	set synonyms_view_url [export_vars -no_empty -base synonyms-view { category_id tree_id locale object_id ctx_id}]
	if { [template::util::is_true $deprecated_p] } {
	    set phase_in_url [export_vars -no_empty -base category-phase-in { category_id tree_id locale object_id ctx_id}]
	} else {
	    set phase_out_url [export_vars -no_empty -base category-phase-out { category_id tree_id locale object_id ctx_id}]
	}
    }
}

set elements [list]

if { $can_write_p } {
    lappend elements edit {
	sub_class narrow
	display_template {
	    <img src="/resources/acs-subsite/Edit16.gif" height="16" width="16" alt="Edit" style="border:0">
	}
	link_url_col edit_url
	link_html {title "#categories.Edit_category_link_title#"}
    }
}

lappend elements category_name {
    label "#categories.Category#"
    display_template {
	@one_tree.left_indent;noquote@<a href="@one_tree.usage_url@" title="Show usage of this category">@one_tree.category_name@</a>
	<if @one_tree.deprecated_p@ true>(#categories.Deprecated# - <a href="@one_tree.phase_in_url@">#categories.Restore#</a>)</if>
    }
}

if { $can_write_p } {
    lappend elements add_child {
	sub_class narrow
	display_template {
	    <img src="/resources/acs-subsite/Add16.gif" height="16" width="16" alt="Add" style="border:0">
	}
	link_url_col add_url
	link_html { title "#categories.Add_subcategory_link_title#" }
    }
    lappend elements sort_key {
	label "#categories.Ordering#"
	display_template {
	    <input name="sort_key.@one_tree.category_id@" value="@one_tree.sort_key@" size="8">
	}
    }
    lappend elements actions {
	label "#categories.Actions#"
	display_template {
	    <a href="@one_tree.parent_url@">#categories.Action_change_parent#</a> &nbsp; &nbsp;
	    <a href="@one_tree.links_view_url@">#categories.Action_view_links#</a> &nbsp; &nbsp;
	    <a href="@one_tree.synonyms_view_url@">#categories.Action_view_synonyms#</a>
	}
    }

    lappend elements delete {
	sub_class narrow
	display_template {
	    <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" alt="Delete" style="border:0">
	}
	link_url_col delete_url
	link_html { title "#categories.Delete_category_link_title#" }
    }
}

set actions [list]
set bulk_actions [list]
if { $can_write_p } {
    set bulk_actions {
	"#categories.Delete#" "category-delete" "#categories.Delete_category_link_title#"
	"#categories.Deprecate#" "category-phase-out" "#categories.Deprecate_category_link_title#"
	"#categories.Restore#" "category-phase-in" "#categories.Restore_category_link_ttitle#"
	"#categories.Ordering_update#" "tree-order-update" "#categories.Ordering_update_link_title#"
    }
    set actions [list \
		     "#categories.Action_add_root#" [export_vars -no_empty -base category-form { tree_id locale object_id ctx_id}] "#categories.Action_add_root_link_title#" \
		     "#categories.Action_copy_tree#" [export_vars -no_empty -base tree-copy { tree_id locale object_id ctx_id}] "#categories.Action_copy_tree_link_title#" \
		     "#categories.Action_delete_tree#" [export_vars -no_empty -base tree-delete { tree_id locale object_id ctx_id}] "#categories.Action_delete_tree_link_title#" \
		     "#categories.Action_applications#" [export_vars -no_empty -base tree-usage { tree_id locale object_id ctx_id}] "#categories.Action_applications_link_title#"]

    if { $can_grant_p } {
	lappend actions "#acs-kernel.common_Permissions#" [export_vars -no_empty -base permission-manage { tree_id locale object_id ctx_id}] "#categories.Action_permissions_link_title#"
    }

}

template::list::create \
    -name one_tree \
    -elements $elements \
    -key category_id \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars { tree_id locale object_id ctx_id}

ad_return_template
