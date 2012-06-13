ad_library {
    Procedures for initializing service contracts etc. for the
    workflow package. Should only be executed once upon installation.
    
    @creation-date 13 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::install {}



#####
#
# Install procs
#
#####

ad_proc -private workflow::install::package_install {} {
    Workflow package install proc
} {

    db_transaction {

        create_service_contracts

        register_implementations
        
        register_notification_types
    }
}

ad_proc -private workflow::install::package_uninstall {} {
    Workflow package uninstall proc
} {
    db_transaction {

        unregister_notification_types

        unregister_implementations
        
        delete_service_contracts

    }
}

ad_proc -private workflow::install::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Workflow package after upgrade callback proc
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            1.2 2.0d1 {
                set workflow_ids [db_list select_workflow_ids { select workflow_id from workflows }]
                foreach workflow_id $workflow_ids {
                    workflow::definition_changed_handler \
                        -workflow_id $workflow_id
                }
            }
        }
}


#####
#
# Create service contracts
#
#####

ad_proc -private workflow::install::create_service_contracts {} {
    Create the service contracts needed by workflow
} {

    db_transaction {

        workflow::install::create_default_assignees_service_contract

        workflow::install::create_assignee_pick_list_service_contract

        workflow::install::create_assignee_subquery_service_contract

        workflow::install::create_action_side_effect_service_contract

        workflow::install::create_activity_log_format_title_service_contract

        workflow::install::create_get_notification_info_service_contract
    }
}


ad_proc -private workflow::install::delete_service_contracts {} {
    
    db_transaction {

        acs_sc::contract::delete -name [workflow::service_contract::role_default_assignees]
        
        acs_sc::contract::delete -name [workflow::service_contract::role_assignee_pick_list]
        
        acs_sc::contract::delete -name [workflow::service_contract::role_assignee_subquery]

        acs_sc::contract::delete -name [workflow::service_contract::action_side_effect]
        
        acs_sc::contract::delete -name [workflow::service_contract::activity_log_format_title]
    
        acs_sc::contract::delete -name [workflow::service_contract::notification_info]
    }
}
    
ad_proc -private workflow::install::create_default_assignees_service_contract {} {

    set default_assignees_spec {
        description "Get default assignees for a role in a workflow case"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output { object_type:string }
                iscachable_p "t"
            }
            GetPrettyName {
                description "Get the pretty name of this implementation."
                output { pretty_name:string }
                iscachable_p "t"
            }
            GetAssignees {
                description "Get the assignees as a Tcl list of party_ids, of the default assignees for this case, object, role"
                input {
                    case_id:integer
                    object_id:integer
                    role_id:integer
                }
                output {
                    party_ids:integer,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::role_default_assignees]] $default_assignees_spec]
}

ad_proc -private workflow::install::create_assignee_pick_list_service_contract {} {

    set assignee_pick_list_spec {
        description "Get the most likely assignees for a role in a workflow case"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output { object_type:string }
                iscachable_p "t"
            }
            GetPrettyName {
                description "Get the pretty name of this implementation."
                output { pretty_name:string }
                iscachable_p "t"
            }
            GetPickList {
                description "Get the most likely assignees for this case, object and role, as a Tcl list of party_ids"
                input {
                    case_id:integer
                    object_id:integer
                    role_id:integer
                }
                output {
                    party_ids:integer,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::role_assignee_pick_list]] $assignee_pick_list_spec]
}

ad_proc -private workflow::install::create_assignee_subquery_service_contract {} {
    
    set assignee_subquery_spec {
        description "Get the name of a subquery to use when searching for users"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output { object_type:string }
                iscachable_p "t"
            }
            GetPrettyName {
                description "Get the pretty name of this implementation."
                output { pretty_name:string }
                iscachable_p "t"
            }
            GetSubquery {
                description "Get a subquery which will return the list of parties who can be assigned to the role, e.g. simply the name of a view of users/parties, or a subquery enclosed in parenthesis such as '(select * from parties where ...)'"
                input {
                    case_id:integer
                    object_id:integer
                    role_id:integer
                }
                output {
                    subquery:string
                }
            }
        }
    }

    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::role_assignee_subquery]] $assignee_subquery_spec]
}

ad_proc -private workflow::install::create_action_side_effect_service_contract {} {

    set side_effect_spec {
        description "Get the name of the side effect to create action"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output { object_type:string }
                iscachable_p "t"
            }
            GetPrettyName { 
                description "Get the pretty name of this implementation."
                output { pretty_name:string }
                iscachable_p "t"
            }
            DoSideEffect {
                description "Do the side effect"
                input {
                    case_id:integer
                    object_id:integer
                    action_id:integer
                    entry_id:integer
                }
            }
        } 
    }  
    
    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::action_side_effect]] $side_effect_spec]
    
}

ad_proc -private workflow::install::create_activity_log_format_title_service_contract {} {
        
    set format_title_spec {
        description "Output additional details for the title of an activity log entry"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output {
                    object_type:string
                }
                iscachable_p "t"
            }
            GetPrettyName {
                description "Get the pretty name of this implementation. Will be localized, so it may contain #...#."
                output { pretty_name:string }
                iscachable_p "t"
            }
            GetTitle {
                description "Get the title name of this implementation."
                input { 
                    case_id:integer
                    object_id:integer
                    action_id:integer
                    entry_id:integer
                    data_arraylist:string,multiple
                } 
                output { 
                    title:string 
                }
                iscachable_p "t"
            }
        }
    }
    
    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::activity_log_format_title]] $format_title_spec]
}

ad_proc -private workflow::install::create_get_notification_info_service_contract {} {
        
    set notification_info_spec {
        description "Get information for notifications"
        operations {
            GetObjectType {
                description "Get the object type for which this implementation is valid."
                output {
                    object_type:string
                }
                iscachable_p "t"
            }
            GetPrettyName {
                description "Get the pretty name of this implementation. Will be localized, so it may contain #...#."
                output { pretty_name:string }
                iscachable_p "t"
            }
            GetNotificationInfo {
                description "Get the notification information as a 4-element list containing url, one-line summary, details about the object in the form of an array-list with label/value, and finally an optional tag for the notification subject, in the order mentioned here."
                input { 
                    case_id:integer
                    object_id:integer
                } 
                output { 
                    info:string,multiple
                }
                iscachable_p "f"
            }
        }
    }
    
    acs_sc::contract::new_from_spec \
            -spec [concat [list name [workflow::service_contract::notification_info]] $notification_info_spec]
}

#####
#
# Register implementations
#
#####

ad_proc -private workflow::install::register_implementations {} {
    Register service contract implementations
} { 

    db_transaction {

        workflow::install::register_default_assignees_creation_user_impl

        workflow::install::register_default_assignees_static_assignee_impl

        workflow::install::register_pick_list_current_assignee_impl 
        
        workflow::install::register_search_query_registered_users_impl

        workflow::install::register_notification_impl

    }

}

ad_proc -private workflow::install::unregister_implementations {} {
    Unregister service contract implementations
} {

    db_transaction {

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_default_assignees]  \
                -impl_name "Role_DefaultAssignees_CreationUser"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_default_assignees] \
                -impl_name "Role_DefaultAssignees_StaticAssignees"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_assignee_pick_list] \
                -impl_name "Role_PickList_CurrentAssignees"

        acs_sc::impl::delete \
                -contract_name [workflow::service_contract::role_assignee_subquery] \
                -impl_name "Role_AssigneeSubquery_RegisteredUsers"

        acs_sc::impl::delete \
                -contract_name "NotificationType" \
                -impl_name "WorkflowNotificationType"
    }
}

ad_proc -private workflow::install::register_default_assignees_creation_user_impl {} {

    set spec {
        name "Role_DefaultAssignees_CreationUser"
        aliases {
            GetObjectType workflow::impl::acs_object
            GetPrettyName workflow::impl::role_default_assignees::creation_user::pretty_name
            GetAssignees  workflow::impl::role_default_assignees::creation_user::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees] 
    lappend spec owner [workflow::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private workflow::install::register_default_assignees_static_assignee_impl {} {

    set spec {
        name "Role_DefaultAssignees_StaticAssignees"
        aliases {
            GetObjectType workflow::impl::acs_object
            GetPrettyName workflow::impl::role_default_assignees::static_assignees::pretty_name
            GetAssignees  workflow::impl::role_default_assignees::static_assignees::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees] 
    lappend spec owner [workflow::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private workflow::install::register_pick_list_current_assignee_impl {} {

    set spec {
        name "Role_PickList_CurrentAssignees"
        aliases {
            GetObjectType workflow::impl::acs_object
            GetPrettyName workflow::impl::role_assignee_pick_list::current_assignees::pretty_name
            GetPickList   workflow::impl::role_assignee_pick_list::current_assignees::get_pick_list 
        }  
    }

    lappend spec contract_name [workflow::service_contract::role_assignee_pick_list]
    lappend spec owner [workflow::package_key]

    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private workflow::install::register_search_query_registered_users_impl {} {

    set spec {
        name "Role_AssigneeSubquery_RegisteredUsers"
        aliases {
            GetObjectType   workflow::impl::acs_object
            GetPrettyName   workflow::impl::role_assignee_subquery::registered_users::pretty_name
            GetSubquery     workflow::impl::role_assignee_subquery::registered_users::get_subquery
        }  
    }
    
    lappend spec contract_name [workflow::service_contract::role_assignee_subquery]
    lappend spec owner [workflow::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private workflow::install::register_notification_impl {} {
    
    set spec {
        contract_name "NotificationType"
        name "WorkflowNotificationType"
	owner "workflow"
	pretty_name "Workflow Notifications"
        aliases {
            GetURL       workflow::impl::notification::get_url
            ProcessReply workflow::impl::notification::process_reply
        }  
    }
    
    lappend spec owner [workflow::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}


#####
#
# Notifications
#
#####

ad_proc -public workflow::install::register_notification_types {} {
    Register workflow notification types
} {
    set sc_impl_id [acs_sc::impl::get_id -owner [workflow::package_key] -name "WorkflowNotificationType"]
    
    set type_id [list]
    
    lappend type_ids [notification::type::new \
            -sc_impl_id $sc_impl_id \
            -short_name "workflow_assignee" \
            -pretty_name "Workflow Assignee" \
            -description "Notification of people who are assigned to an action in a workflow."]
    
    lappend type_ids [notification::type::new \
            -sc_impl_id $sc_impl_id \
            -short_name "workflow_my_cases" \
            -pretty_name "Workflow My Cases" \
            -description "Notification on all activity in any case you're participating in."]

    lappend type_ids [notification::type::new \
            -sc_impl_id $sc_impl_id \
            -short_name "workflow_case" \
            -pretty_name "Workflow Case" \
            -description "Notification on all activity in a specific case that you're interested in."]

    lappend type_ids [notification::type::new \
            -sc_impl_id $sc_impl_id \
            -short_name "workflow" \
            -pretty_name "Workflow" \
            -description "Notification on all activity in any case in a particular workflow (typically an instance of a package)."]

    # Enable all available intervals and delivery methods    
    foreach type_id $type_ids {
        db_dml enable_all_intervals {}
        db_dml enable_all_delivery_methods {}
    }
}

ad_proc -public workflow::install::unregister_notification_types {} {
    Unregister workflow notification types
} {
    db_transaction {
        notification::type::delete -short_name "workflow_assignee"
        notification::type::delete -short_name "workflow_my_cases"
        notification::type::delete -short_name "workflow_case"
        notification::type::delete -short_name "workflow"
    }
}

