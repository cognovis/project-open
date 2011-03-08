ad_page_contract {
    Add or edit a category.
} {
    keyword_id:integer,optional
    parent_id:integer,optional
    {type_p "f"}
}

set project_name [bug_tracker::conn project_name]

if { (![info exists keyword_id] && ![info exists parent_id]) || [string equal $type_p "t"] } {
    set object_type_name "Category Type"
} else {
    set object_type_name "Category"
}

if { [info exists keyword_id] } {
    set function "Edit"
} else {
    set function "Add"
}

set page_title "$function $object_type_name"
set context_bar [ad_context_bar [list categories "Manage Categories"] $page_title]


ad_form -name keyword -cancel_url categories -form {
    {keyword_id:key(acs_object_id_seq)}
    {parent_id:integer(hidden)}
    {heading:text {label $object_type_name}}
} -new_request {
    if { ![exists_and_not_null parent_id] } {
        set parent_id [bug_tracker::conn project_root_keyword_id]
    }
} -select_query {
    select child.parent_id, 
           child.heading
    from   cr_keywords child
    where  child.keyword_id = :keyword_id
} -edit_data {
    cr::keyword::set_heading \
        -keyword_id $keyword_id \
        -heading $heading
} -new_data {
    cr::keyword::new \
        -heading $heading \
        -parent_id $parent_id \
        -keyword_id $keyword_id
} -after_submit {
    bug_tracker::get_keywords_flush
    ad_returnredirect categories
    ad_script_abort
}
