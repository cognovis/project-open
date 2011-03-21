ad_page_contract {
    Subscribe to all bugs available to the current user
} {
    {unwatch 0}
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

set type_id [notification::type::get_type_id -short_name "workflow_case"]
set delivery_methods [notification::get_delivery_methods -type_id $type_id]
set delivery_method_id [lindex [lindex $delivery_methods 0] 1]

set bugs [bug_tracker::get_watch_bugs -type_id $type_id -user_id $user_id -watched $unwatch]

foreach bug_id $bugs {
    if {$unwatch==0} {
	notification::security::require_notify_object -object_id $bug_id

	notification::request::new \
	    -type_id $type_id \
	    -user_id $user_id \
	    -object_id $bug_id \
	    -interval_id [notification::interval::get_id_from_name -name "instant"] \
	    -delivery_method_id $delivery_method_id
    } else {
        set request_id [notification::request::get_request_id \
                            -type_id $type_id \
                            -object_id $bug_id \
                            -user_id $user_id]

	notification::request::delete -request_id $request_id
    }
}

ad_returnredirect $return_url

