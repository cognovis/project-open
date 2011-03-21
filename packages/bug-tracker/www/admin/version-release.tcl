ad_page_contract {
    Release version
} {
    version_id:integer
}

set page_title "Release Version"

set context [list [list versions "Versions"] $page_title]

ad_form -name version -cancel_url versions -form {
    version_id:key
    {version_name:text {mode display} {label "Version Name"}}
    {anticipated_release_date:date,to_sql(sql_date),to_html(sql_date),optional
        {mode display} {label "Anticipated release date"}
    }
    {actual_release_date:date,to_sql(sql_date),to_html(sql_date)
        {label "Actual release date"}
    }
} -select_query_name version_select -edit_data {
    db_dml update_version {}
} -after_submit {
    bug_tracker::versions_flush
    
    ad_returnredirect versions
    ad_script_abort
}
