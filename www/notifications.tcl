ad_page_contract {
    Manage bug-tracker notifications
} {
    bug_number:integer,optional
}

set page_title "Notifications"
set context [list $page_title]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]
if { [exists_and_not_null bug_number] } {
    set bug_id [bug_tracker::get_bug_id \
                    -bug_number $bug_number \
                    -project_id [ad_conn package_id]]

    set case_id [workflow::case::get_id \
                     -object_id $bug_id \
                     -workflow_short_name [bug_tracker::bug::workflow_short_name]]
} else {
    set case_id {}
}

set user_id [ad_conn user_id]
set return_url [ad_return_url]

multirow create notifications url label title subscribed_p

foreach type { 
    workflow_assignee workflow_my_cases workflow
} {
    set object_id [workflow::case::get_notification_object \
                       -type $type \
                       -workflow_id $workflow_id \
                       -case_id $case_id]

    if { ![empty_string_p $object_id] } {
        switch $type {
            workflow_assignee {
                set pretty_name "all [bug_tracker::conn bugs] you're assigned to"
            }
            workflow_my_cases {
                set pretty_name "all [bug_tracker::conn bugs] you're participating in"
            }
            workflow {
                set pretty_name "all [bug_tracker::conn bugs] in this project"
            }
            default {
                error "Unknown type"
            }
        }

        # Get the type id
        set type_id [notification::type::get_type_id -short_name $type]

        # Check if subscribed
        set request_id [notification::request::get_request_id \
                            -type_id $type_id \
                            -object_id $object_id \
                            -user_id $user_id]

        set subscribed_p [expr ![empty_string_p $request_id]]
        
        if { $subscribed_p } {
            set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
        } else {
            set url [notification::display::subscribe_url \
                         -type $type \
                         -object_id $object_id \
                         -url $return_url \
                         -user_id $user_id \
                         -pretty_name $pretty_name]
        }

        if { ![empty_string_p $url] } {
            multirow append notifications \
                $url \
                [string totitle $pretty_name] \
                [ad_decode $subscribed_p 1 "Unsubscribe from $pretty_name" "Subscribe to $pretty_name"] \
                $subscribed_p
        }
    }
}

set manage_url "[apm_package_url_from_key [notification::package_key]]manage"
