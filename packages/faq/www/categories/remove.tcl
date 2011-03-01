ad_page_contract {
} {
    object_id:integer,notnull
    cat:integer,notnull
}

db_dml nuke {delete from category_object_map where category_id = :cat and object_id = :object_id}

ad_returnredirect -message "removed category" [get_referrer]
