ad_library {
  Test helper procedure library for the acs-automated-testing tests
  of the workflow package.

  @author Peter Marklund
  @creation-date 10 January 2003
  @cvs-id $Id$
}

namespace eval workflow::test {}

ad_proc workflow::test::workflow_name {} {
    The short name used for the Bug Tracker Bug test
    workflow. It is assumed this short name will not be
    present in the system.
} {
    return "bug_test"
}

ad_proc workflow::test::initial_action_short_name {} {
    The short name of the initial action of the test workflow
} {
    return "open"
}

ad_proc workflow::test::workflow_object_id {} {
    Return a dummy object_id for use for the workflow stuff.
} {
    return [db_string main_site_package_id {
        select object_id
        from   site_nodes
        where  parent_id is null
    }]
}

ad_proc workflow::test::workflow_object_id_2 {} {

} {
    return [db_string some_object_id {select min(object_id) from acs_objects where object_type = 'apm_parameter'}]
}

ad_proc workflow::test::workflow_id {} {
    Get the id of the Bug Tracker bug workflow
} {
    return [workflow::get_id \
            -object_id [workflow::test::workflow_object_id] \
            -short_name [workflow::test::workflow_name]]
}

ad_proc workflow::test::admin_owner_id {} {
    Return the id of the site-wide-admin (the only person
    guaranteed to be on the system).
} {
    set admin_email [ad_admin_owner]

    return [db_string admin_owner_id "select party_id from parties where email = :admin_email"]
}

ad_proc workflow::test::action_short_names { action_id_list } {

    Return the short names of the actions with given id:s
} {
    set short_name_list [list]
    foreach action_id $action_id_list {
        workflow::action::get -action_id $action_id -array action_info

        lappend short_name_list $action_info(short_name)
    }

    return $short_name_list
}

ad_proc workflow::test::assert_case_state {
    {-workflow_id:required}
    {-case_id:required}
    {-user_id {}}
    {-expect_current_state:required}
    {-expect_enabled_actions:required} 
    -expect_user_actions
} {
    Make assertions about what the current state should be and
    what actions are enabled etc.
} {
    set actual_states [list]
    foreach elm [workflow::case::fsm::get_state_info -all -case_id $case_id] {
        foreach { parent_action_id state_id } $elm {}
        lappend actual_states [workflow::state::fsm::get_element -state_id $state_id -element short_name]
    }

    if { ![aa_true "Current states should be: $expect_current_state" \
               [util_sets_equal_p $expect_current_state $actual_states]] } {
        aa_log "States are: $actual_states"
    }


    set enabled_actions [workflow::test::action_short_names \
            [workflow::case::get_enabled_actions -case_id $case_id]]
    
    if { ![aa_true "Enabled actions should be: $expect_enabled_actions" \
               [util_sets_equal_p $enabled_actions $expect_enabled_actions]] } {
        aa_log "Enabled actions are: $enabled_actions"
    }

    if { [info exists expect_user_actions] } { 
        if { [empty_string_p $user_id] } {
            set user_id [workflow::test::admin_owner_id]
        }
        set user_actions [workflow::test::action_short_names \
                              [workflow::case::get_available_actions \
                                   -case_id $case_id \
                                   -user_id $user_id]]
        
        if { ![aa_true "Available user actions for user $user_id should be: $expect_user_actions" \
                   [util_sets_equal_p $user_actions $expect_user_actions]] } {
            aa_log "Available user actions are: $user_actions"
        }
    }
}

ad_proc workflow::test::assert_user_actions {
    {-workflow_id:required}
    {-case_id:required}
    {-user_id {}}
    {-expect_user_actions {}}
} {
    Make assertions about user actions.
} {
    if { [empty_string_p $user_id] } {
        set user_id [workflow::test::admin_owner_id]
    }
    set user_actions [workflow::test::action_short_names \
                          [workflow::case::get_available_actions \
                               -case_id $case_id \
                               -user_id $user_id]]
    
    if { ![aa_true "Available user actions for user $user_id should be: $expect_user_actions" \
               [util_sets_equal_p $user_actions $expect_user_actions]] } {
        aa_log "Available user actions are: $user_actions"
    }
}


ad_proc workflow::test::get_message_key_spec {} {
    Get a workflow array style spec containing message keys.
} {
    set spec {
        pretty_name "#acs-subsite.About_You#"
        package_key "acs-automated-testing"
        object_type "acs_object"
        roles {
            short_name {
                pretty_name "#acs-subsite.Bad_Password#"
            }
        }
        states {
            foobar {
                pretty_name "#acs-subsite.Basic_Information#"
            }
        }
        actions {
            foobar {
                pretty_name "#acs-subsite.Confirm#"
                pretty_past_tense "#acs-subsite.Confirm#"
                trigger_type init
            }
        }
    }

    return [list test_message_keys $spec]
}

ad_proc workflow::test::workflow_get_array_style_spec {} {
    Get the array-style spec for a workflow for the Bug Tracker 
    Bug use case.
} {
    set spec {
        pretty_name "Bug Test"
        package_key "acs-automated-testing"
        object_type "acs_object"
        roles {
            submitter {
                pretty_name "Submitter"
                callbacks { 
                    workflow.Role_DefaultAssignees_CreationUser
                }
            }
            assignee {
                pretty_name "Assignee"
            }
        }
        states {
            open {
                pretty_name "Open"
            }
            resolved {
                pretty_name "Resolved"
            }
            closed {
                pretty_name "Closed"
            }
        }
        actions {
            open {
                pretty_name "Open"
                pretty_past_tense "Opened"
                new_state "open"
                trigger_type init
            }
            comment {
                pretty_name "Comment"
                pretty_past_tense "Commented"
                allowed_roles { submitter assignee }
                privileges read
                always_enabled_p t
            }
            edit {
                pretty_name "Edit"
                pretty_past_tense "Edited"
                allowed_roles { submitter assignee }
                privileges write
                always_enabled_p t
            }
            resolve {
                pretty_name "Resolve"
                pretty_past_tense "Resolved"
                assigned_role assignee
                enabled_states { resolved }
                assigned_states { open }
                new_state "resolved"
                privileges write
            }
            close {
                pretty_name "Close"
                pretty_past_tense "Closed"
                assigned_role submitter
                assigned_states resolved
                new_state "closed"
                privileges write
            }
            reopen {
                pretty_name "Reopen"
                pretty_past_tense "Closed"
                allowed_roles submitter
                enabled_states { resolved closed }
                new_state "open"
                privileges write
            }
        }
    }
    set spec [list [workflow::test::workflow_name] $spec]
    
    return $spec
}

ad_proc workflow::test::workflow_setup_array_style {} {
    Create a test workflow for the Bug Tracker 
    Bug use case.
} {
    # Cannot use bt_bug as we cannot assume Bug Tracker to be installed

    set workflow_id [workflow::fsm::new_from_spec \
            -object_id [workflow::test::workflow_object_id] \
            -spec [workflow::test::workflow_get_array_style_spec]]

    return $workflow_id
}

ad_proc workflow::test::array_lists_equal_p { list1 list2 } {
    Are the two lists equal?
} {
    set len1 [llength $list1]
    set len2 [llength $list2]

    if { $len1 != $len2 } {
        return 0
    }

    if { $len1 == 1 } {

        # Single element list

        return [string equal [lindex $list1 0] [lindex $list2 0]]
    } elseif { [expr $len1 % 2] == 0 } {

        # List, treat as array-list

        array set array1 $list1
        array set array2 $list2
        
        foreach name [lsort [array names array1]] {
            if { ![info exists array2($name)] } {
                # Element in 1 doesn't exist in 2
                return 0
            }

            set elm1 $array1($name)
            set elm2 $array2($name)

            if { ![array_lists_equal_p $elm1 $elm2] } {
                return 0
            }
        }
    } else {
        
        # List, treat as normal list
        
        foreach elm1 $list1 elm2 $list2 {
            if { ![array_lists_equal_p $elm1 $elm2] } {
                return 0
            }
        }
    }

    return 1
}

ad_proc workflow::test::workflow_setup {} {
    Create a test workflow for the Bug Tracker 
    Bug use case.
} {
    #####
    #
    # Workflow
    #
    #####

    # Cannot use bt_bug as we cannot assume Bug Tracker to be installed

    set workflow_id [workflow::new \
            -short_name [workflow::test::workflow_name] \
            -pretty_name "Bug Test" \
            -package_key "acs-automated-testing" \
            -object_id [workflow::test::workflow_object_id] \
            -object_type "acs_object" ]

    #####
    #
    # Roles
    #
    #####

    workflow::role::new -workflow_id $workflow_id \
            -short_name "submitter" \
            -pretty_name "Submitter" \
            -callbacks workflow.Role_DefaultAssignees_CreationUser

    workflow::role::new -workflow_id $workflow_id \
            -short_name "assignee" \
            -pretty_name "Assignee" \

    #####
    #
    # States
    #
    #####

    workflow::state::fsm::new -workflow_id $workflow_id \
            -short_name "open" \
            -pretty_name "Open"
    
    workflow::state::fsm::new -workflow_id $workflow_id \
            -short_name "resolved" \
            -pretty_name "Resolved"
    
    workflow::state::fsm::new -workflow_id $workflow_id \
            -short_name "closed" \
            -pretty_name "Closed"

    #####
    #
    # Actions
    #
    #####

    workflow::action::fsm::new \
            -trigger_type init \
            -workflow_id $workflow_id \
            -short_name [workflow::test::initial_action_short_name] \
            -pretty_name "Open" \
            -pretty_past_tense "Opened" \
            -new_state "open"                              
    
    workflow::action::fsm::new \
            -workflow_id $workflow_id \
            -short_name "comment" \
            -pretty_name "Comment" \
            -pretty_past_tense "Commented" \
            -allowed_roles { submitter assignee } \
            -privileges read \
            -always_enabled_p t

    workflow::action::fsm::new \
            -workflow_id $workflow_id \
            -short_name "edit" \
            -pretty_name "Edit" \
            -pretty_past_tense "Edited" \
            -allowed_roles { submitter assignee } \
            -privileges write \
            -always_enabled_p t

    workflow::action::fsm::new \
            -workflow_id $workflow_id \
            -short_name "resolve" \
            -pretty_name "Resolve" \
            -pretty_past_tense "Resolved" \
            -assigned_role assignee \
            -enabled_states resolved \
            -assigned_states open \
            -new_state "resolved" \
            -privileges write

    workflow::action::fsm::new \
            -workflow_id $workflow_id \
            -short_name "close" \
            -pretty_name "Close" \
            -pretty_past_tense "Closed" \
            -assigned_role submitter \
            -assigned_states resolved \
            -new_state "closed" \
            -privileges write

    workflow::action::fsm::new \
            -workflow_id $workflow_id \
            -short_name "reopen" \
            -pretty_name "Reopen" \
            -pretty_past_tense "Closed" \
            -allowed_roles submitter \
            -enabled_states { resolved closed } \
            -new_state "open" \
            -privileges write    

    return $workflow_id
}

ad_proc workflow::test::workflow_teardown {} {
   Delete the Bug Tracker Bug test workflow.
} {
    # We don't care about error here
    catch { 
        set workflow_id [workflow_id]

        workflow::delete -workflow_id $workflow_id
    }
}


ad_proc workflow::test::case_setup {} {
    Create a case of the Bug Tracker bug test workflow.

    @author Peter Marklund
} {
    set workflow_id [workflow::test::workflow_id]
    
    set case_id [workflow::case::new -workflow_id $workflow_id \
                                     -object_id [workflow::test::workflow_object_id] \
                                     -comment "Test workflow case" \
                                     -comment_mime_type "text/plain" \
                                     -user_id [workflow::test::admin_owner_id]]

    return $case_id
}

ad_proc workflow::test::run_with_teardown {
    test_chunk
    teardown_chunk
} {
    Execute code in test chunk and guarantee that code in 
    teardown_chunk will be executed even if error is thrown by the test_chunk.

    @author Peter Marklund
} {
    set error_p [catch $test_chunk errMsg]

    global errorInfo
    set setup_error_stack $errorInfo

    # Teardown
    eval $teardown_chunk

    if { $error_p } {    
        aa_false "error during setup: $errMsg - $setup_error_stack" $error_p
    }
}

ad_proc workflow::test::run_bug_tracker_test {
    {-create_proc "workflow_setup"}
} {
    # Make sure to run the teardown proc even if there is an error
    set test_chunk {
        # Setup

        set workflow_id [$create_proc]

        set generated_spec [workflow::fsm::generate_spec -workflow_id $workflow_id]
        
        if { ![aa_true "Checking that generated spec 1 is identical to the spec that we created from (except for ordering)" \
                   [array_lists_equal_p $generated_spec [workflow_get_array_style_spec]]] } {
            ns_log Error "Workflow test case failed: \nDesired spec: [workflow_get_array_style_spec]\n\nActual spec:\n\n[util::array_list_spec_pretty $generated_spec]"
        }
    
        # Create the workflow case in open state
        set object_id [workflow::test::workflow_object_id]
        set case_id [workflow::test::case_setup]
    
        set retrieved_case_id \
                [workflow::case::get_id \
                -object_id $object_id \
                -workflow_short_name [workflow::test::workflow_name]]
        
        # Test the workflow::get proc
        workflow::get -workflow_id $workflow_id -array workflow_array
        aa_equals "checking the short_name retrieved with workflow::get of workflow" \
                $workflow_array(short_name) \
                [workflow::test::workflow_name]
        
        set retrieved_initial_action_name [workflow::action::get_element \
                                            -action_id $workflow_array(initial_action_id) \
                                            -element short_name]

        aa_equals "Checking initial action short name from workflow::get and workflow::action::get_element" \
                $retrieved_initial_action_name [workflow::test::initial_action_short_name]

        
        # Test changing the short_name and check that the flush is cached
        # TODO...

        # Get the role short_names
        set expect_role_names [list submitter assignee]
        foreach role_id [workflow::get_roles -workflow_id $workflow_id] {
            workflow::role::get -role_id $role_id -array role

            aa_true "checking that role names of workflow can be fetched with workflow::get_roles and workflow::role::get" \
                  [expr [lsearch -exact $expect_role_names $role(short_name)] != -1]

        }

        # Get the action short names
        set expect_action_names [list open comment edit resolve close reopen]
        foreach action_id [workflow::get_actions -workflow_id $workflow_id] {
            workflow::action::get -action_id $action_id -array action

            aa_true "checking retrieval of action names with workflow::get_actions and workflow::get" \
                    [expr [lsearch -exact $expect_action_names $action(short_name)] != -1]

        }

        # Get the state short names
        # TODO

        aa_true "case_id of a created workflow case should be retrievable" \
                [string equal $case_id $retrieved_case_id]
    
        set expect_enabled_actions [list comment edit resolve]
        workflow::test::assert_case_state \
                -workflow_id $workflow_id \
                -case_id $case_id \
                -expect_current_state open \
                -expect_enabled_actions $expect_enabled_actions \
                -expect_user_actions $expect_enabled_actions
    
        # Resolve the bug
        workflow::case::action::execute \
                -case_id $case_id \
                -action_id [workflow::action::get_id -workflow_id $workflow_id \
                -short_name "resolve"] \
                -comment "Resolving Bug" \
                -comment_mime_type "text/plain" \
                -user_id [workflow::test::admin_owner_id]
        
        set expect_enabled_actions [list comment edit resolve reopen close]
        workflow::test::assert_case_state \
                -workflow_id $workflow_id \
                -case_id $case_id \
                -expect_current_state resolved \
                -expect_enabled_actions $expect_enabled_actions \
                -expect_user_actions $expect_enabled_actions


        #####
        #
        # Intermezzo: Check cache and flushing
        #
        #####

        # -1. Basic sanity check
        aa_equals "Stat is resolved" [workflow::case::get_element -case_id $case_id -element state_short_name] "resolved"

        # 0. Desired output
        global desired_output 
        set desired_output [workflow::case::fsm::get_info_not_cached $case_id]

        # 1. Make sure the cache is populated
        set dummy [workflow::case::get_element -case_id $case_id -element state_short_name]

        with_catch errmsg {

            # 2. Stub the cache proc
            aa_stub workflow::case::fsm::get_info_not_cached {
                # Note that we got called
                global i_got_called_p desired_output
                set i_got_called_p 1
                
                return $desired_output
            }
            global i_got_called_p
        
            # 3. Check that it doesn't call stubbed proc
            set i_got_called_p 0
            set dummy [workflow::case::get_element -case_id $case_id -element state_short_name]
            aa_false "Check that the value is in the cache (1st time)" $i_got_called_p
            
            # 4. Flush
            workflow::case::flush_cache -case_id $case_id
            
            # 5. Check that it DOES call stubbed proc
            set i_got_called_p 0
            set dummy [workflow::case::get_element -case_id $case_id -element state_short_name]
            aa_true "Check that the value is NOT in the cache (1st time)" $i_got_called_p
            
            # 6. Manually populate the cache
            util_memoize_seed [list workflow::case::fsm::get_info_not_cached $case_id] $desired_output [workflow::case::cache_timeout]
            
            # 7. Check that it doesn't call stubbed proc
            set i_got_called_p 0
            set dummy [workflow::case::get_element -case_id $case_id -element state_short_name]
            aa_false "Check that the value is in the cache (2nd time)" $i_got_called_p
            
            # 8. Flush
            workflow::case::flush_cache
            
            # 9. Check that it DOES call stubbed proc
            set i_got_called_p 0
            set dummy [workflow::case::get_element -case_id $case_id -element state_short_name]
            aa_true "Check that the value is NOT in the cache (2nd time)" $i_got_called_p
        } {
            aa_unstub workflow::case::fsm::get_info_not_cached
            
            global errorInfo
            error $errmsg $errorInfo
        }
        
        # 10. Unstub
        aa_unstub workflow::case::fsm::get_info_not_cached

        
        #####
        #
        # Continue with case
        #
        #####
                                  
        # Close the bug
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id -workflow_id $workflow_id \
                            -short_name "close"] \
            -comment "Closing Bug" \
            -comment_mime_type "text/plain" \
            -user_id [workflow::test::admin_owner_id]
        
        set expect_enabled_actions [list comment edit reopen]
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state closed \
            -expect_enabled_actions $expect_enabled_actions \
            -expect_user_actions $expect_enabled_actions
    
    } 

    set error_p [catch $test_chunk errMsg]

    # Teardown
    workflow::test::workflow_teardown

    if { $error_p } {    
        global errorInfo
        aa_false "error during setup: $errMsg - $errorInfo" $error_p
    }
}



#####
#
# Register the test cases
#
#####

aa_register_case bugtracker_workflow_create_normal {
    Test creation and teardown of an FSM workflow case.
} {
    workflow::test::run_bug_tracker_test -create_proc "workflow::test::workflow_setup"
}

aa_register_case bugtracker_workflow_create_array_style {
    Test creation and teardown of an FSM workflow case, with array style specification.

    @author Lars Pind
    @creation-date 21 January 2003
} {
    workflow::test::run_bug_tracker_test -create_proc "workflow::test::workflow_setup_array_style"
}

aa_register_case bugtracker_workflow_clone {
    Test creation and teardown of cloning an FSM workflow case.

    @author Lars Pind
    @creation-date 22 January 2003
} {
    set workflow_id_list [list]
    set test_chunk {
        set workflow_id_1 [workflow::test::workflow_setup]
        lappend workflow_id_list $workflow_id_1
        set workflow_id_2 [workflow::fsm::clone -workflow_id $workflow_id_1 -object_id [workflow::test::workflow_object_id_2]]
        lappend workflow_id_list $workflow_id_2

        set spec_1 [workflow::fsm::generate_spec -workflow_id $workflow_id_1]
        set spec_2 [workflow::fsm::generate_spec -workflow_id $workflow_id_2]

        aa_true "Generated spec from original and cloned workflow should be identical" \
                [string equal $spec_1 $spec_2]
    } 

    set error_p [catch $test_chunk errMsg]

    # Teardown
    foreach workflow_id $workflow_id_list {
        workflow::delete -workflow_id $workflow_id
    }

    if { $error_p } {    
        global errorInfo
        aa_false "error during setup: $errMsg - $errorInfo" $error_p
    }
}

aa_register_case workflow_spec_with_message_keys {
    Test creating a workflow from a spec with message catalog
    keys.
} {
    set test_chunk {

        set workflow_id [workflow::fsm::new_from_spec \
            -spec [workflow::test::get_message_key_spec]]

        set generated_spec [workflow::fsm::generate_spec -workflow_id $workflow_id]
        
        if { ![aa_true "Checking that generated spec 2 is identical to the spec that we created from (except for ordering)" \
                   [array_lists_equal_p $generated_spec [workflow::test::get_message_key_spec]]] } {
            ns_log Error "Workflow test case failed: \nDesired spec: [workflow::test::get_message_key_spec]\n\nActual spec:\n\n[util::array_list_spec_pretty $generated_spec]"
        }
    }

    set teardown_chunk {
        set workflow_id [workflow::get_id -package_key acs-automated-testing -short_name test_message_keys]
        workflow::delete -workflow_id $workflow_id
    }
    
    workflow::test::run_with_teardown $test_chunk $teardown_chunk
}


aa_register_case workflow_automatic_action {
    Test workflow with automatic action.
} {
    workflow::test::run_with_teardown {
        # Define workflow
        
        set workflow_id [workflow::new \
                             -short_name "test_automatic_ations" \
                             -pretty_name "Testing Automatic Actions" \
                             -package_key "acs-automated-testing"]

        # [open] -> (open) -> [auto] -> (closed)

        workflow::state::fsm::new \
            -workflow_id $workflow_id \
            -short_name "open" \
            -pretty_name "Open"

        workflow::state::fsm::new -workflow_id $workflow_id \
            -short_name "closed" \
            -pretty_name "Closed"

        workflow::action::fsm::new \
            -trigger_type init \
            -workflow_id $workflow_id \
            -short_name [ad_generate_random_string] \
            -pretty_name "Open" \
            -new_state "open"                              

        set auto_action_id [workflow::action::fsm::new \
                                -workflow_id $workflow_id \
                                -short_name "auto" \
                                -pretty_name "Auto" \
                                -enabled_states "open" \
                                -new_state "closed" \
                                -trigger_type auto]

        # Start a case

        set case_id [workflow::case::new \
                         -workflow_id $workflow_id \
                         -object_id [workflow::test::workflow_object_id] \
                         -user_id [workflow::test::admin_owner_id]]

        # Check that it's now in 'closed' state
        set current_state [workflow::case::fsm::get_current_state -case_id $case_id]
        set current_state_short [workflow::state::fsm::get_element -state_id $current_state -element short_name]

        aa_equals "Case is closed" $current_state_short "closed"

        # Change the action to be timed

        set update_cols(timeout_seconds) 1
        set update_cols(trigger_type) "time"
        workflow::action::fsm::edit \
            -action_id $auto_action_id \
            -array update_cols
        
        set case_id [workflow::case::new \
                         -workflow_id $workflow_id \
                         -object_id [db_string objid { select max(object_id) from acs_objects } ] \
                         -user_id [workflow::test::admin_owner_id]]

        # Check that it's now in 'open' state
        set current_state [workflow::case::fsm::get_current_state -case_id $case_id]
        set current_state_short [workflow::state::fsm::get_element -state_id $current_state -element short_name]

        aa_equals "Case is open" $current_state_short "open"
        
        # Run sweeper
        ns_sleep 1
        workflow::case::timed_actions_sweeper

        # Check that it's now in 'closed' state
        set current_state [workflow::case::fsm::get_current_state -case_id $case_id]
        set current_state_short [workflow::state::fsm::get_element -state_id $current_state -element short_name]

        aa_equals "Case is closed" $current_state_short "closed"

        # Add another action

        # Old process: [open] -> (open) -> [auto] -> (closed)
        # New process: [open] -> (open) -> [auto] -> (closed) -> [reopen] -> (open)

        set reopen_action_id [workflow::action::fsm::new \
                                  -workflow_id $workflow_id \
                                  -short_name "reopen" \
                                  -pretty_name "Reopen" \
                                  -enabled_states "closed" \
                                  -new_state "open"]

        # The new action should now be anabled
        aa_true "New 'reopen' action is enabled" [workflow::case::action::enabled_p \
                                                      -case_id $case_id \
                                                      -action_id $reopen_action_id]

        # Execute it
        workflow::case::action::execute \
            -no_perm_check \
            -case_id $case_id \
            -action_id $reopen_action_id

        # The new action should now be anabled
        aa_false "New 'reopen' action is not enabled" [workflow::case::action::enabled_p \
                                                           -case_id $case_id \
                                                           -action_id $reopen_action_id]

        # Case should be open
        set current_state [workflow::case::fsm::get_current_state -case_id $case_id]
        set current_state_short [workflow::state::fsm::get_element -state_id $current_state -element short_name]
        aa_equals "Case is open" $current_state_short "open"
        
        # The new action should now be anabled again
        aa_true "Timed 'close' action is enabled" [workflow::case::action::enabled_p \
                                                       -case_id $case_id \
                                                       -action_id $auto_action_id]
        # Run sweeper
        ns_sleep 1
        workflow::case::timed_actions_sweeper

        # Check that it's now in 'closed' state
        set current_state [workflow::case::fsm::get_current_state -case_id $case_id]
        set current_state_short [workflow::state::fsm::get_element -state_id $current_state -element short_name]

        aa_equals "Case is closed" $current_state_short "closed"

        # The new action should now be anabled again
        aa_true "New 'reopen' action is enabled" [workflow::case::action::enabled_p \
                                                      -case_id $case_id \
                                                      -action_id $reopen_action_id]

    } {
        set workflow_id [workflow::get_id -package_key "acs-automated-testing" -short_name "test_automatic_ations"]
        workflow::delete -workflow_id $workflow_id
    }
}


aa_register_case hierarchical_workflow {
    Testing a hierarchical workflow
} {
    aa_run_with_teardown -rollback -test_code {

        #----------------------------------------------------------------------
        # Create hierarchical workflow
        #----------------------------------------------------------------------

        #  action_id                 | trigger  |ask_cl|ask_lwr|lac-ask|lac-give|cal-ask|cal-give
        # ---------------------------+----------+------+-------+-------+--------+-------+---------
        #  open                      | init     |      |       |       |        |       |
        #  lawyer_asks_client        | workflow |  X   |       |       |        |       |
        #    lawyer_asks_client_init | init     |      |       |       |        |       |
        #    lawyer_asks_client_ask  | user     |      |       |   X   |        |       |
        #    lawyer_asks_client_give | user     |      |       |       |   X    |       |
        #  client_asks_lawyer        | workflow |      |   X   |       |        |       |
        #    client_asks_lawyer_init | init     |      |       |       |        |       |
        #    client_asks_lawyer_ask  | user     |      |       |       |        |   X   |
        #    client_asks_lawyer_give | user     |      |       |       |        |       |   X

        set workflow_id [workflow::fsm::new_from_spec -package_key "acs-automated-testing" -spec {
            hierarchical_workflow {
                pretty_name "Hierarchical Workflow"
                states {
                    asking_client { 
                        pretty_name "Asking Client" 
                        enabled_actions { lawyer_asks_client } 
                    }
                    asking_lawyer { 
                        pretty_name "Asking Lawyer" 
                        enabled_actions { client_asks_lawyer } 
                    }
                    done { 
                        pretty_name "Done" 
                    }
                    lawyer_asks_client_asking { 
                        pretty_name "AC-Asking" 
                        parent_action "lawyer_asks_client" 
                        enabled_actions { lawyer_asks_client_ask }
                    }
                    lawyer_asks_client_giving { 
                        pretty_name "AC-Giving" 
                        parent_action "lawyer_asks_client" 
                        enabled_actions { lawyer_asks_client_give }
                    }
                    lawyer_asks_client_done { 
                        pretty_name "AC-Done" 
                        parent_action "lawyer_asks_client" 
                    }
                    client_asks_lawyer_asking { 
                        pretty_name "AL-Asking" 
                        parent_action "client_asks_lawyer" 
                        enabled_actions { client_asks_lawyer_ask }
                    }
                    client_asks_lawyer_giving { 
                        pretty_name "AL-Giving" 
                        parent_action "client_asks_lawyer" 
                        enabled_actions { client_asks_lawyer_give }
                    }
                    client_asks_lawyer_done { 
                        pretty_name "AL-Done" 
                        parent_action "client_asks_lawyer" 
                    }
                }
                roles {
                    lawyer {
                        pretty_name "Lawyer"
                    }
                    client {
                        pretty_name "Client"
                    }
                }
                actions {
                    open {
                        pretty_name "Open"
                        pretty_past_tense "Opened"
                        new_state "asking_client"
                        trigger_type init
                    }
                    lawyer_asks_client {
                        pretty_name "Lawyer asks client"
                        pretty_past_tense "Lawyer asked client"
                        new_state "asking_lawyer"
                        trigger_type workflow
                    }
                    lawyer_asks_client_init {
                        pretty_name "Lawyer asks client-Init"
                        pretty_past_tense "Lawyer asked client-Init"
                        trigger_type init
                        parent_action "lawyer_asks_client"
                        new_state "lawyer_asks_client_asking"
                    }
                    lawyer_asks_client_ask {
                        pretty_name "Ask client"
                        pretty_past_tense "Asked client"
                        parent_action "lawyer_asks_client"
                        new_state "lawyer_asks_client_giving"
                        assigned_role "lawyer"
                    }
                    lawyer_asks_client_give {
                        pretty_name "Respond to lawyer"
                        pretty_past_tense "Responded to lawyer"
                        parent_action "lawyer_asks_client"
                        new_state "lawyer_asks_client_done"
                        assigned_role "client"
                    }
                    client_asks_lawyer {
                        pretty_name "Client asks lawyer"
                        pretty_past_tense "Client asked lawyer"
                        enabled_states { asking_lawyer }
                        new_state "done"
                        trigger_type workflow
                    }
                    client_asks_lawyer_init {
                        pretty_name "Client asks lawyer-Init"
                        pretty_past_tense "Client asked lawyer-Init"
                        trigger_type init
                        parent_action "client_asks_lawyer"
                        new_state "client_asks_lawyer_asking"
                    }
                    client_asks_lawyer_ask {
                        pretty_name "Ask lawyer"
                        pretty_past_tense "Asked lawyer"
                        parent_action "client_asks_lawyer"
                        enabled_states { client_asks_lawyer_asking }
                        new_state "client_asks_lawyer_giving"
                        assigned_role "client"
                    }
                    client_asks_lawyer_give {
                        pretty_name "Respond to client"
                        pretty_past_tense "Responded to client"
                        parent_action "client_asks_lawyer"
                        enabled_states { client_asks_lawyer_giving }
                        new_state "client_asks_lawyer_done"
                        assigned_role "lawyer"
                    }
                }
            }
        }]

        #----------------------------------------------------------------------
        # Test the state-action map
        #----------------------------------------------------------------------

        array set state_action_map {
            asking_client { lawyer_asks_client } 
            asking_lawyer { client_asks_lawyer }
            done {}
            lawyer_asks_client_asking { lawyer_asks_client_ask }
            lawyer_asks_client_giving { lawyer_asks_client_give }
            lawyer_asks_client_done {}
            client_asks_lawyer_asking { client_asks_lawyer_ask }
            client_asks_lawyer_giving { client_asks_lawyer_give }
            client_asks_lawyer_done {}
        }
        foreach state [array names state_action_map] {
            set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name $state]
            set enabled_actions [workflow::state::fsm::get_element -state_id $state_id -element enabled_actions]
            #aa_true "Enabled actions in state $state are $enabled_actions, should be $state_action_map($state)" \
                [util_sets_equal_p $state_action_map($state) $enabled_actions]
        }


        #----------------------------------------------------------------------
        # Start a case of the workflow
        #----------------------------------------------------------------------

        aa_log "Starting case."

        set case_id [workflow::case::new \
                         -workflow_id $workflow_id \
                         -object_id [workflow::test::workflow_object_id] \
                         -user_id [workflow::test::admin_owner_id]]
        
        #----------------------------------------------------------------------
        # 'lawyer_asks_client_ask' should now be available
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "asking_client" "lawyer_asks_client_asking" } \
            -expect_enabled_actions "lawyer_asks_client_ask"

        #----------------------------------------------------------------------
        # Execute 'lawyer_asks_client_ask'
        #----------------------------------------------------------------------
        
        aa_log "Executing: lawyer_asks_client_ask"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "lawyer_asks_client_ask"] \
            -comment "Lawyer asks" \
            -comment_mime_type "text/plain" \
            -user_id [workflow::test::admin_owner_id]

        #----------------------------------------------------------------------
        # Enabled action: 'lawyer_asks_client_give'
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "asking_client" "lawyer_asks_client_giving" } \
            -expect_enabled_actions "lawyer_asks_client_give"

        #----------------------------------------------------------------------
        # Execute 'lawyer_asks_client_give'
        #----------------------------------------------------------------------

        aa_log "Executing: lawyer_asks_client_give"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "lawyer_asks_client_give"] \
            -comment "Client responds" \
            -comment_mime_type "text/plain" \
            -user_id [workflow::test::admin_owner_id]


        #----------------------------------------------------------------------
        # 'client_asks_lawyer_ask' should now be available
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "asking_lawyer" "client_asks_lawyer_asking" } \
            -expect_enabled_actions "client_asks_lawyer_ask"

        
        #----------------------------------------------------------------------
        # Execute 'client_asks_lawyer_ask'
        #----------------------------------------------------------------------

        aa_log "Executing: client_asks_lawyer_ask"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "client_asks_lawyer_ask"] \
            -comment "Client asks" \
            -comment_mime_type "text/plain" \
            -user_id [workflow::test::admin_owner_id]

        #----------------------------------------------------------------------
        # Enabled action: 'client_asks_lawyer_give'
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "asking_lawyer" "client_asks_lawyer_giving" } \
            -expect_enabled_actions "client_asks_lawyer_give"

        #----------------------------------------------------------------------
        # Execute 'client_asks_lawyer_give'
        #----------------------------------------------------------------------

        aa_log "Executing: client_asks_lawyer_give"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "client_asks_lawyer_give"] \
            -comment "Lawyer responds" \
            -comment_mime_type "text/plain" \
            -user_id [workflow::test::admin_owner_id]

        #----------------------------------------------------------------------
        # 'done', Nothing enabled
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "done" } \
            -expect_enabled_actions [list]
    }
        
}


aa_register_case parallel_simple_workflow {
    Testing a simple parallel workflow
} {
    aa_run_with_teardown -rollback -test_code {

        #----------------------------------------------------------------------
        # Create parallel workflow
        #----------------------------------------------------------------------
        #  action_id                 | trigger  |  s1  |  s2  | done  |
        # ---------------------------+----------+------+------+-------+
        #  inti                      | init     |      |      |       |
        #  task_one                  | parallel |  X   |      |       |
        #    para_a                  | user     |      |      |       |
        #    para_b                  | user     |      |      |       |
        #  task_two                  | user     |      |  X   |       |

        set workflow_id [workflow::fsm::new_from_spec -package_key "acs-automated-testing" -spec {
            parallel_simple {
                pretty_name "Simple Parallel"
                states {
                    s1 {
                        pretty_name "S1"
                        enabled_actions { task_one } 
                    }
                    s2 { 
                        pretty_name "S2" 
                        enabled_actions { task_two }
                    }
                    done { 
                        pretty_name "Done" 
                    }
                }
                roles {
                    role1 {
                        pretty_name "Role1"
                    }
                    role2 {
                        pretty_name "Role2"
                    }
                }
                actions {
                    init {
                        pretty_name "Open"
                        new_state "s1"
                        trigger_type init
                    }
                    task_one {
                        pretty_name "Task 1 (parallel)"
                        new_state "s2"
                        trigger_type parallel
                    }
                    para_a {
                        pretty_name "Para A (user)"
                        parent_action "task_one"
                        assigned_role role1
                    }
                    para_b {
                        pretty_name "Para B (user)"
                        parent_action "task_one"
                        assigned_role role2
                    }
                    task_two {
                        pretty_name "Task 2 (user)"
                        new_state "done"
                        assigned_role role1
                    }
                }
            }
        }]
        
        #----------------------------------------------------------------------
        # Test the state-action map
        #----------------------------------------------------------------------

        array set state_action_map {
            s1 { task_one } 
            s2 { task_two }
            done {}
        }
        foreach state [array names state_action_map] {
            set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name $state]
            set enabled_actions [workflow::state::fsm::get_element -state_id $state_id -element enabled_actions]
            aa_true "Enabled actions in state $state are $enabled_actions, should be $state_action_map($state)" \
                [util_sets_equal_p $state_action_map($state) $enabled_actions]
        }

        #----------------------------------------------------------------------
        # Start a case of the workflow
        #----------------------------------------------------------------------

        aa_log "Starting case."

        set case_id [workflow::case::new \
                         -workflow_id $workflow_id \
                         -object_id [workflow::test::workflow_object_id] \
                         -user_id [workflow::test::admin_owner_id]]
    
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "s1" } \
            -expect_enabled_actions { "para_a" "para_b" }

        #----------------------------------------------------------------------
        # Execute 'para_b'
        #----------------------------------------------------------------------
        
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "para_b"] \
            -user_id [workflow::test::admin_owner_id]

        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "s1" } \
            -expect_enabled_actions "para_a"

        #----------------------------------------------------------------------
        # Execute 'para_a'
        #----------------------------------------------------------------------

        aa_log "Executing: para_a"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "para_a"] \
            -user_id [workflow::test::admin_owner_id]


        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "s2" } \
            -expect_enabled_actions "task_two"

        #----------------------------------------------------------------------
        # Execute 'task_two'
        #----------------------------------------------------------------------

        aa_log "Executing: task_two"
        workflow::case::action::execute \
            -case_id $case_id \
            -action_id [workflow::action::get_id \
                            -workflow_id $workflow_id \
                            -short_name "task_two"] \
            -user_id [workflow::test::admin_owner_id]

        #----------------------------------------------------------------------
        # 'done', Nothing enabled
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { "done" } \
            -expect_enabled_actions [list]
    }
        
}


aa_register_case dynamic_simple_workflow {
    Testing a simple parallel workflow
} {
    aa_run_with_teardown -rollback -test_code {

        #----------------------------------------------------------------------
        # Create dynamic workflow
        #----------------------------------------------------------------------
        #  action_id                 | trigger  |  s1  |  s2  | done  |
        # ---------------------------+----------+------+------+-------+
        #  inti                      | init     |      |      |       |
        #  task_one                  | dynamic  |  X   |      |       |
        #    dyn                     | user     |      |      |       |
        #  task_two                  | user     |      |  X   |       |

        set workflow_id [workflow::fsm::new_from_spec -package_key "acs-automated-testing" -spec {
            dynamic_simple {
                pretty_name "Simple Dynamic Test Workflow"
                states {
                    s1 {
                        pretty_name "S1"
                        assigned_actions { task_one } 
                    }
                    s2 { 
                        pretty_name "S2" 
                        assigned_actions { task_two }
                    }
                    done { 
                        pretty_name "Done" 
                    }
                }
                roles {
                    role1 {
                        pretty_name "Role1"
                    }
                    role2 {
                        pretty_name "Role2"
                    }
                }
                actions {
                    init {
                        pretty_name "Open"
                        new_state "s1"
                        trigger_type init
                    }
                    task_one {
                        pretty_name "Task 1 (dynamic)"
                        new_state "s2"
                        trigger_type dynamic
                    }
                    dyn {
                        pretty_name "Dynamic (user)"
                        parent_action "task_one"
                        assigned_role role1
                    }
                    task_two {
                        pretty_name "Task 2 (user)"
                        new_state "done"
                        assigned_role role2
                    }
                }
            }
        }]
        
        #----------------------------------------------------------------------
        # Test the state-action map
        #----------------------------------------------------------------------

        array set state_action_map {
            s1 { task_one } 
            s2 { task_two }
            done {}
        }
        foreach state [array names state_action_map] {
            set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name $state]
            set enabled_actions [workflow::state::fsm::get_element -state_id $state_id -element enabled_actions]
            aa_true "Enabled actions in state $state are $enabled_actions, should be $state_action_map($state)" \
                [util_sets_equal_p $state_action_map($state) $enabled_actions]
        }

        #----------------------------------------------------------------------
        # Create the required users
        #----------------------------------------------------------------------
        
        array set r1u1_array [auth::create_user -username [ad_generate_random_string] -email "[ad_generate_random_string]@test.test" \
                                  -first_names [ad_generate_random_string] -last_name [ad_generate_random_string]]
        set r1u1 $r1u1_array(user_id)

        array set r1u2_array [auth::create_user -username [ad_generate_random_string] -email "[ad_generate_random_string]@test.test" \
                                  -first_names [ad_generate_random_string] -last_name [ad_generate_random_string]]
        set r1u2 $r1u2_array(user_id)

        array set r2u1_array [auth::create_user -username [ad_generate_random_string] -email "[ad_generate_random_string]@test.test" \
                                  -first_names [ad_generate_random_string] -last_name [ad_generate_random_string]]
        set r2u1 $r2u1_array(user_id)

        #----------------------------------------------------------------------
        # Start a case of the workflow
        #----------------------------------------------------------------------

        aa_log "Starting case."

        set case_id [workflow::case::new \
                         -workflow_id $workflow_id \
                         -object_id [workflow::test::workflow_object_id] \
                         -user_id [workflow::test::admin_owner_id] \
                         -assignment [list role1 [list $r1u1 $r1u2] role2 [list $r2u1]]]
    
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { s1 } \
            -expect_enabled_actions { dyn dyn }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u1 \
            -expect_user_actions { dyn }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u2 \
            -expect_user_actions { dyn }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r2u1 \
            -expect_user_actions { }

        #----------------------------------------------------------------------
        # Execute 'sub' as r1u2
        #----------------------------------------------------------------------

        set enabled_action_id [workflow::case::get_available_enabled_action_ids \
                                   -case_id $case_id \
                                   -user_id $r1u2]
        
        workflow::case::action::execute \
            -case_id $case_id \
            -enabled_action_id $enabled_action_id \
            -user_id $r1u2

        #----------------------------------------------------------------------
        # Available should now be 'sub' as r1u1
        #----------------------------------------------------------------------

        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { s1 } \
            -expect_enabled_actions { dyn }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u1 \
            -expect_user_actions { dyn }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u2 \
            -expect_user_actions { }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r2u1 \
            -expect_user_actions { }

        #----------------------------------------------------------------------
        # Execute 'sub' as r1u1
        #----------------------------------------------------------------------

        set enabled_action_id [workflow::case::get_available_enabled_action_ids \
                                   -case_id $case_id \
                                   -user_id $r1u1]
        
        workflow::case::action::execute \
            -case_id $case_id \
            -enabled_action_id $enabled_action_id \
            -user_id $r1u1

        #----------------------------------------------------------------------
        # Available should now be 'task_two' as r2u1
        #----------------------------------------------------------------------

        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { s2 } \
            -expect_enabled_actions { task_two }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u1 \
            -expect_user_actions { }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r1u2 \
            -expect_user_actions { }

        workflow::test::assert_user_actions \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -user_id $r2u1 \
            -expect_user_actions { task_two }

        #----------------------------------------------------------------------
        # Execute 'task_two'
        #----------------------------------------------------------------------

        set enabled_action_id [workflow::case::get_available_enabled_action_ids \
                                   -case_id $case_id \
                                   -user_id $r2u1]
        
        workflow::case::action::execute \
            -case_id $case_id \
            -enabled_action_id $enabled_action_id \
            -user_id $r2u1

        #----------------------------------------------------------------------
        # 'done', Nothing enabled
        #----------------------------------------------------------------------
        
        workflow::test::assert_case_state \
            -workflow_id $workflow_id \
            -case_id $case_id \
            -expect_current_state { done } \
            -expect_enabled_actions { } \
            -expect_user_actions { }
    }
        
}
