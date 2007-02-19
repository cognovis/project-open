ad_page_contract {

    Deletes a synonym

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    synonym_id:integer,multiple
    category_id:integer,notnull
    tree_id:integer,notnull
    {locale ""}
    object_id:integer,optional
} -properties {
    page_title:onevalue
    context_bar:onevalue
    locale:onevalue
    delete_url:onevalue
    cancel_url:onevalue
}

set user_id [ad_maybe_redirect_for_registration]
permission::require_permission -object_id $tree_id -privilege category_tree_write

set tree_name [category_tree::get_name $tree_id $locale]
set category_name [category::get_name $category_id $locale]
set page_title "Delete synonyms of category \"$tree_name :: $category_name\""

set context_bar [category::context_bar $tree_id $locale [value_if_exists object_id]]
lappend context_bar [list [export_vars -no_empty -base synonyms-view { category_id tree_id locale object_id }] "Synonyms of $category_name"] "Delete synonyms"

set delete_url [export_vars -no_empty -base synonym-delete-2 { synonym_id:multiple category_id tree_id locale object_id }]
set cancel_url [export_vars -no_empty -base synonyms-view { category_id tree_id locale object_id }]


db_multirow synonyms get_synonyms_to_delete ""

template::list::create \
    -name synonyms \
    -no_data "None" \
    -elements {
	synonym_name {
	    label "Name"
	}
	language {
	    label "Language"
	}
    }

ad_return_template 
