ad_library {

    Bug Tracker Install library
    
    Procedures that deal with installing, instantiating, mounting.

    @creation-date 2003-01-31
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id $Id$
}


namespace eval bug_tracker::install {}

ad_proc -private bug_tracker::install::package_install {} {
    Package installation callback proc
} {
    db_transaction {
        bug_tracker::install::register_implementations
        bug_tracker::bug::workflow_create
    }
}

ad_proc -private bug_tracker::install::package_uninstall {} {
    Package un-installation callback proc
} {
    db_transaction {
        bug_tracker::bug::workflow_delete
        bug_tracker::install::unregister_implementations
    }
}

ad_proc -private bug_tracker::install::package_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Package before-upgrade callback
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            0.9d1 1.2d2 {
                # This is the upgrade that converts Bug Tracker to using the workflow package
                ns_log Notice "bug_tracker::install::package_upgrade - Upgrading Bug Tracker from 09d1 to 1.2d2"

                # This sets up the the but tracker package type workflow instance
                package_install

                # Create a workflow instance for each Bug Tracker project
                db_foreach select_project_ids {} {
                    bug_tracker::bug::instance_workflow_create -package_id $project_id
                }
            }
            1.3a6 1.3a7 {
                ns_log Notice "bug_tracker::install::package_upgrade - Upgrading Bug Tracker from 1.3a6 to 1.3a7"
                # Previous upgrades added workflow and workflow cases but not enabled actions
                # for each workflow case.  Bug.
                db_foreach select_case_ids {} {
                    workflow::case::state_changed_handler -case_id $case_id
                }
            }
        }
}

ad_proc -private bug_tracker::install::package_instantiate {
    {-package_id:required}
} {
    Package instantiation callback proc
} {
    # Create the project
    bug_tracker::project_new $package_id

    bug_tracker::bug::instance_workflow_create -package_id $package_id
}

ad_proc -private bug_tracker::install::package_uninstantiate {
    {-package_id:required}
} {
    Package un-instantiation callback proc
} {

    bug_tracker::project_delete $package_id
    bug_tracker::bug::instance_workflow_delete -package_id $package_id

}

#####
#
# Service contract implementations
#
#####

ad_proc -private bug_tracker::install::register_implementations {} {
    db_transaction {
        bug_tracker::install::register_capture_resolution_code_impl
        bug_tracker::install::register_project_maintainer_impl
        bug_tracker::install::register_component_maintainer_impl
        bug_tracker::install::register_format_log_title_impl
        bug_tracker::install::register_bug_notification_info_impl
    }
}

ad_proc -private bug_tracker::install::unregister_implementations {} {
    db_transaction {

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::action_side_effect] \
                -impl_name "CaptureResolutionCode"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::activity_log_format_title] \
                -impl_name "FormatLogTitle"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_default_assignees]  \
                -impl_name "ComponentMaintainer"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_default_assignees] \
                -impl_name "ProjectMaintainer"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::notification_info] \
                -impl_name "BugNotificationInfo"
    }
}

ad_proc -private bug_tracker::install::register_capture_resolution_code_impl {} {

    set spec {
        name "CaptureResolutionCode"
        aliases {
            GetObjectType bug_tracker::bug::object_type
            GetPrettyName bug_tracker::bug::capture_resolution_code::pretty_name
            DoSideEffect  bug_tracker::bug::capture_resolution_code::do_side_effect
        }
    }
    
    lappend spec contract_name [workflow::service_contract::action_side_effect] 
    lappend spec owner [bug_tracker::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private bug_tracker::install::register_component_maintainer_impl {} {

    set spec {
        name "ComponentMaintainer"
        aliases {
            GetObjectType bug_tracker::bug::object_type
            GetPrettyName bug_tracker::bug::get_component_maintainer::pretty_name
            GetAssignees  bug_tracker::bug::get_component_maintainer::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees]
    lappend spec owner [bug_tracker::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private bug_tracker::install::register_project_maintainer_impl {} {

    set spec {
        name "ProjectMaintainer"
        aliases {
            GetObjectType bug_tracker::bug::object_type
            GetPrettyName bug_tracker::bug::get_project_maintainer::pretty_name
            GetAssignees  bug_tracker::bug::get_project_maintainer::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees]
    lappend spec owner [bug_tracker::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}
        
ad_proc -private bug_tracker::install::register_format_log_title_impl {} {

    set spec {
        name "FormatLogTitle"
        aliases {
            GetObjectType bug_tracker::bug::object_type
            GetPrettyName bug_tracker::bug::format_log_title::pretty_name
            GetTitle      bug_tracker::bug::format_log_title::format_log_title
        }
    }
    
    lappend spec contract_name [workflow::service_contract::activity_log_format_title]
    lappend spec owner [bug_tracker::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private bug_tracker::install::register_bug_notification_info_impl {} {

    set spec {
        name "BugNotificationInfo"
        aliases {
            GetObjectType       bug_tracker::bug::object_type
            GetPrettyName       bug_tracker::bug::notification_info::pretty_name
            GetNotificationInfo bug_tracker::bug::notification_info::get_notification_info
        }
    }
    
    lappend spec contract_name [workflow::service_contract::notification_info]
    lappend spec owner [bug_tracker::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

