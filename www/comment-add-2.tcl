ad_page_contract {
    Add a comment to the journal for a case.
} {
    action:array
    case_id:integer
    msg
    return_url:optional
}

if { [info exists action(comment)] } {
    wf_case_comment $case_id $msg
}

if { ![info exists return_url] } {
    set return_url case?[export_url_vars case_id]
}

ad_returnredirect $return_url