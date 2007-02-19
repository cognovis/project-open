ad_page_contract  {
    Delete the subscription, and maybe the report.
} {
    subscr_id:notnull,naturalnum
    return_url:notnull
    delete_file_p:optional
}

ad_require_permission $subscr_id admin

if [info exists delete_file_p] {
    ns_unlink -nocomplain [rss_gen_report_file -subscr_id $subscr_id]
}

db_exec_plsql delete_subscr {}

ad_returnredirect $return_url
