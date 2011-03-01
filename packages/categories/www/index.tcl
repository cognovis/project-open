ad_page_contract {

    The index page to browse category trees.

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    {search_text:optional ""}
} -properties {
    page_title:onevalue
    context_bar:onevalue
    trees:multirow
}

set page_title "Categories"
set context_bar ""

set user_id [auth::require_login]
set package_id [ad_conn package_id]
set locale [ad_conn locale]

set admin_p [permission::permission_p -object_id $package_id -privilege category_admin]

template::multirow create trees tree_ids tree_name site_wide_p short_name

db_foreach get_trees "" {
    if { $has_read_p == "t" || $site_wide_p == "t" } {
	set tree_name [category_tree::get_name $tree_id $locale]
	template::multirow append trees $tree_id $tree_name $site_wide_p
    }
}

template::multirow sort trees -dictionary tree_name

template::list::create \
    -name trees \
    -key tree_ids \
    -no_data "None" \
    -bulk_actions {
	"Browse" "categories-browse" "Browse through selected category trees"
    } -elements {
	tree_name {
	    label "Name"
	}
    }

ad_form -name search_form -action . -form {
    {search_text:text {label "Search String"} {value $search_text} {html {size 50 maxlength 200}}}
} -on_submit {
    set query_id [category_synonym::search -search_text [string trim $search_text] -locale $locale]
} -after_submit {
    ad_returnredirect [export_vars -no_empty -base search-result {query_id}]
    ad_script_abort
}

ad_return_template
