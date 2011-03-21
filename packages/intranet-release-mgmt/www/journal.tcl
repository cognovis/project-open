# assume that the following are set:
#    object_id


set workflow_url [apm_package_url_from_key "acs-workflow"]
set return_url [ns_urlencode "[ad_conn url]?[ad_conn query]"]

if { ![info exists date_format] || [empty_string_p $date_format] } {
    set date_format "Mon fmDDfm, YYYY HH24:MI:SS"
}

if { ![info exists order] || [empty_string_p $order] } {
    set order latest_first
}

if { ![info exists comment_link] || [empty_string_p $comment_link] } {
    set comment_link 1
}

switch -- $order {
    latest_first {
	set sql_order "desc"
    }
    latest_last {
	set sql_order "asc"
    }
    default {
	return -code error "Order must be latest_first or latest_last"
    }
}

set entries [list]
db_multirow journal journal_select ""

