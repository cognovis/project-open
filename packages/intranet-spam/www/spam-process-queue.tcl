ad_page_contract {
    Flush any remaining spam messages.

} { 
    { return_url "/intranet/" }
}

acs_mail_process_queue

ad_returnredirect $return_url
