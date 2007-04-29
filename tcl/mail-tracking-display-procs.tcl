ad_library {

    Mail-Tracking Display Procs.

    Mail-Tracking is mostly a service package, but it does have some level of user interface.
    These procs enable other packages to simply register for tracking.

    @creation-date 2005-05-31
    @author Nima Mazloumi <mazloumi@uni-mannheim.de>
    @cvs-id $Id$

}

namespace eval mail_tracking::display {}

ad_proc -public mail_tracking::display::request_widget {
    {-object_id:required}
    {-url:required}
} {
    Produce a widget for requesting tracking. If the mail-tracking package has not been
    mounted then return the empty string.
} {
    # Check that we're mounted
    if { [empty_string_p [apm_package_url_from_key [mail_tracking::package_key]]] } {
        return {}
    }

    #Check if we track already everything
    set track_all_p [ad_parameter -package_id [apm_package_id_from_key [mail_tracking::package_key]] TrackAllMails "0"]

    if {$track_all_p} {
	return ""
    }

    # Check if subscribed
    set request_id [mail_tracking::request::get_request_id -object_id $object_id]

    set pretty_name [acs_object_name $object_id]

    if {![empty_string_p $request_id]} {
        set sub_url [ad_quotehtml [unsubscribe_url -request_id $request_id -url $url]]
        set pretty_name [ad_quotehtml $pretty_name]
        set sub_chunk "[_ mail-tracking.You_have_requested_to_track_emails_from_this_package]"
    } else {
        set sub_url [ad_quotehtml [subscribe_url -object_id $object_id -url $url]]
        set pretty_name [ad_quotehtml $pretty_name]
        set sub_chunk "[_ mail-tracking.You_may_request_mail_tracking_for_this_package]"
    }

    if { [empty_string_p $sub_url] } {
         return ""
    }

    return $sub_chunk
}

ad_proc -public mail_tracking::display::subscribe_url {
    {-object_id:required}
    {-url:required}
} {
    Returns the URL that allows one to subscribe to tracking for a package.   If the
    mail-tracking package has not been mounted return the empty string.
} {
    set root_path [apm_package_url_from_key [mail_tracking::package_key]]

    if { [empty_string_p $root_path] } {
        return ""
    }

    set subscribe_url [export_vars -base "${root_path}request-new" { object_id { return_url $url } }]

    return $subscribe_url
}

ad_proc -public mail_tracking::display::unsubscribe_url {
    {-request_id:required}
    {-url:required}
} {
    Returns the URL that allows one to unsubscribe from a particular request.
} {
    set root_path [apm_package_url_from_key [mail_tracking::package_key]]

    if { [empty_string_p $root_path] } {
        return ""
    }

    set unsubscribe_url [export_vars -base "${root_path}request-delete" { request_id { return_url $url } }]

    return $unsubscribe_url
}
