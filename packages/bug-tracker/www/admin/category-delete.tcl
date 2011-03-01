ad_page_contract {
    Delete category
} {
    keyword_id:integer
}

cr::keyword::delete \
    -keyword_id $keyword_id

bug_tracker::get_keywords_flush

ad_returnredirect categories
