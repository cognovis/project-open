ad_page_contract {
    shows the list of users about to receive a spam message
} {
    { sql_query ""}
    { object_id 0}
} -properties {
    spam_list:multirow
    context:onevalue
}

if {$sql_query == ""} { 
    ad_return_complaint 1 "No user query supplied.  You can't invoke this \
	    page directly."
    return 
}

ad_require_permission $object_id write

db_multirow spam_list spam_get_party_list  {}

set context [list "show users"]
