ad_page_contract {

    Displays matched synonyms for search string

    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id:
} {
    query_id:integer,notnull
} -properties {
    page_title:onevalue
    context_bar:onevalue
}

set user_id [auth::require_login]
set package_id [ad_conn package_id]
set locale [ad_conn locale]

db_1row get_search_string ""
set page_title "Search Result for \"$search_text\""
set context_bar "Search Result"

db_multirow -extend {category_name} search_result get_search_result "" {
    set category_name [category::get_name $category_id $locale]
}


template::list::create \
    -name search_result \
    -key synonym_id \
    -actions [list "New Search" [export_vars -no_empty -base index { search_text }] "New Search"] \
    -elements {
	similarity {
	    label "Similarity"
	}
	synonym_name {
	    label "Search Result"
	    display_template {
		@search_result.synonym_name@<if @search_result.synonym_p@ eq t> (@search_result.category_name@)</if>
	    }
	}
    }

ad_return_template
