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
set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]

multirow create notifications url_on url_off label

set type_id [notification::type::get_type_id -short_name "workflow_case"]

set watched_bugs [llength [bug_tracker::get_watch_bugs -type_id $type_id -user_id $user_id -watched 1]]
set unwatched_bugs [llength [bug_tracker::get_watch_bugs -type_id $type_id -user_id $user_id]]

foreach type { 
    workflow_assignee workflow_my_cases workflow
} {
    set object_id [workflow::case::get_notification_object \
                       -type $type \
                       -workflow_id $workflow_id \
                       -case_id $case_id]

    if { ![empty_string_p $object_id] } {
	set url_on ""
	set url_off ""

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

        if { $request_id != "" } {
            set url_off [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
        } else {
            set url_on [notification::display::subscribe_url \
			    -type $type \
                         -object_id $object_id \
                         -url $return_url \
                         -user_id $user_id \
                         -pretty_name $pretty_name]
        }

	if { $type == "workflow" && !$admin_p} {
	    if { $unwatched_bugs==0 } {
		set url_on ""
	    } else {
		set url_on "watch_all_bugs?return_url=$return_url"
	    }

	    if { $watched_bugs==0 } {
		set url_off ""
	    } else {
		set url_off "watch_all_bugs?return_url=$return_url&unwatch=1"
	    } 
		
	    set pretty_name "all [bug_tracker::conn bugs] currenty available to me (subscribed:$watched_bugs,unsubscribed:$unwatched_bugs)"
	}

	multirow append notifications \
	    $url_on \
	    $url_off \
	    [string totitle $pretty_name]
    }
}

set manage_url "[apm_package_url_from_key [notification::package_key]]manage"
