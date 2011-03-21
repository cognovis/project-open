ad_page_contract {
    Confirm deletion of a subscription.
} {
    subscr_id:notnull,naturalnum
    return_url:notnull
}

ad_require_permission $subscr_id admin

db_1row subscr_info {}

if [string equal $channel_title ""] {
    set channel_title "Summary Context $summary_context_id"
}

set context [list Delete]

if [file exists [rss_gen_report_file -subscr_id $subscr_id]] {
    set offer_file 1
    set report_url [rss_gen_report_file -subscr_id $subscr_id]
} else {
    set offer_file 0
}
