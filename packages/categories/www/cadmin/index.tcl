ad_page_contract {

    The index page of the category trees administration
    presenting a list of trees the person has a permission to see/modify

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    {locale ""}
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    trees_with_write_permission:multirow
    trees_with_read_permission:multirow
}

set page_title "[_ categories.cadmin]"
set context_bar [list $page_title]

set user_id [auth::require_login]
set package_id [ad_conn package_id]

permission::require_permission -object_id $package_id -privilege category_admin

template::multirow create trees_with_write_permission tree_id tree_name site_wide_p description
template::multirow create trees_with_read_permission tree_id tree_name site_wide_p descrption


db_foreach trees {} {
    array unset tree_array
    array set tree_array [category_tree::get_data $tree_id $locale]

    if {$has_write_p == "t"} {
	template::multirow append trees_with_write_permission $tree_id $tree_array(tree_name) $site_wide_p $tree_array(description)
    } elseif { $has_read_p == "t" || $site_wide_p == "t" } {
	template::multirow append trees_with_read_permission $tree_id $tree_name $site_wide_p $tree_array(description)
    }
}

multirow extend trees_with_read_permission view_url
multirow foreach trees_with_read_permission {
    set view_url [export_vars -no_empty -base tree-view { tree_id locale }]
}
multirow sort trees_with_read_permission -dictionary tree_name

multirow extend trees_with_write_permission view_url
multirow foreach trees_with_write_permission {
    set view_url [export_vars -no_empty -base tree-view { tree_id locale }]
}
multirow sort trees_with_write_permission -dictionary tree_name


set elements {
    tree_name {
	label "Name"
	link_url_col view_url
    }
    description {
	label "Description"
    }
}

list::create \
    -name trees_with_write_permission \
    -no_data "None" \
    -elements $elements \
    -key tree_id \
    -bulk_action_export_vars {locale} \
    -bulk_actions [list "[_ categories.export]" trees-code "[_ categories.code_export]"] \

list::create \
    -name trees_with_read_permission \
    -no_data "None" \
    -elements $elements

set create_url [export_vars -no_empty -base tree-form { locale }]
