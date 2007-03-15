ad_page_contract {

} {

}

set user_id [ad_maybe_redirect_for_registration]
set content [im_workflow_home_component]
set return_url [im_url_with_query]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set admin_html ""
if {$user_is_admin_p} {
    set admin_html "<li><a href=\"/workflow/admin/\">#intranet-workflow.Admin_workflows#</a>\n"
#    append admin_html "<li><a href=\"/workflow/admin/cases?state=active\">[lang::message::lookup "" intranet-workflow.Debug_Workflows "Debug Workflows"]</a>\n"
}


# <a href="/notifications/request-new?object_id=@user_id@&type_id=@type_id@&return_url=@return_page@
set notification_object_id [apm_package_id_from_key "acs-workflow"]
set notification_type_id [notification::type::get_type_id -short_name "wf_assignment_notif"]
set notification_delivery_method_id [notification::get_delivery_method_id -name "email"]
set notification_interval_id [notification::get_interval_id -name "instant"]

set notification_subscribe_url [export_vars -base "/notifications/request-new?" {
    {object_id $notification_object_id} 
    {type_id $notification_type_id}
    {delivery_method_id $notification_delivery_method_id}
    {interval_id $notification_interval_id}
    {"form\:id" "subscribe"}
    {formbutton\:ok "OK"}
    return_url
}]


# ----------------------------------------------------
# Create a component to manage subscriptions

multirow create notifications url label title subscribed_p
set manage_url "[apm_package_url_from_key [notification::package_key]]manage"

foreach type { 
    wf_assignment_notif
} {
    set pretty_name "Workflow Assignments"
    set type_id [notification::type::get_type_id -short_name $type]

    # Check if subscribed
    set request_id [notification::request::get_request_id \
                            -type_id $type_id \
                            -object_id $notification_object_id \
                            -user_id $user_id]

    set subscribed_p [expr ![empty_string_p $request_id]]

    if { $subscribed_p } {
	set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
    } else {
	set url [notification::display::subscribe_url \
                         -type $type \
                         -object_id $notification_object_id \
                         -url $return_url \
                         -user_id $user_id \
                         -pretty_name $pretty_name]
	set url $notification_subscribe_url
    }

    if { ![empty_string_p $url] } {
	multirow append notifications \
	    $url \
	    [string totitle $pretty_name] \
	    [ad_decode $subscribed_p 1 "Unsubscribe from $pretty_name" "Subscribe to $pretty_name"] \
	    $subscribed_p
    }
}
