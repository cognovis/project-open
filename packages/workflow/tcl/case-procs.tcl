ad_library {
    Procedures in the case namespace.
    
    @creation-date 13 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::case {}
namespace eval workflow::case::fsm {}
namespace eval workflow::case::action {}
namespace eval workflow::case::role {}
namespace eval workflow::case::action::fsm {}

#####
#
#  workflow::case
#
#####

ad_proc -private workflow::case::insert {
    {-workflow_id:required}
    {-object_id:required}
} {
    Internal procedure that creates a new workflow case in the
    database. Should not be used by applications. Use workflow::case::new instead.

    @param object_id           The object_id which the case is about

    @param workflow_id         The ID of the workflow.

    @return                    The case_id of the case. Returns the empty string if no case could be found.

    @see workflow::case::new

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_transaction {
        set case_id [db_nextval "workflow_cases_seq"]
        
        # Create the case
        db_dml insert_case {}

        # Initialize the FSM state to NULL
        db_dml insert_case_fsm {}
    }
    
    return $case_id
}

ad_proc -public workflow::case::new {
    {-no_notification:boolean}
    -workflow_id:required
    {-object_id {}}
    {-comment {}}
    {-comment_mime_type {}}
    -user_id
    -assignment
} {
    Start a new case for this workflow and object.

    @param object_id           The object_id which the case is about

    @param workflow_id         The ID of the workflow for the case.

    @param comment_mime_type   text/html, text/plain, text/pre, text/enhanced.

    @param assignment          Array-list of role_short_name and list of party_ids to assign 
                               to roles before starting.

    @return                    The case_id of the case.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }
    
    db_transaction {

        # Initial action
        set initial_action_id [workflow::get_element -workflow_id $workflow_id -element initial_action_id]

        if { [empty_string_p $initial_action_id] } {
            # If there is no initial-action, we create one now
            # TODO: Should we do this here, or throw an error like we used to?
            # If we change this, we should throw an error instead

            set action_row(pretty_name) "Start"
            set action_row(pretty_past_tense) "Started"
            set action_row(trigger_type) "init"

            set states [workflow::fsm::get_states -workflow_id $workflow_id]
            
	    if { [llength $states] == 0 } {
		error "workflow $workflow_id doesn't have any states"
	    }

            # We use the first state as the initial state
            set action_row(new_state_id) [lindex $states 0]           	    

            # Add the new initial action
            set initial_action_id [workflow::action::fsm::edit \
                                       -operation "insert" \
                                       -array action_row \
                                       -workflow_id $workflow_id]
	    
	    workflow::flush_cache -workflow_id $workflow_id
	    
        } else {
            # NOTE: FSM-specific check here
            
            workflow::action::fsm::get -action_id $initial_action_id -array initial_action
            set new_state $initial_action(new_state)

            if { [empty_string_p $new_state] } {
                error "Initial action with short_name \"$initial_action(short_name)\" does not have any new_state. In order to be an initial state, it must have new_state set."
            }
        }

        # Insert the case
        set case_id [insert \
                         -workflow_id $workflow_id \
                         -object_id $object_id]

        # Assign roles
        if { [exists_and_not_null assignment] } {
            array set assignment_array $assignment
            workflow::case::role::assign -case_id $case_id -array assignment_array
        }


        # Execute the initial action
        workflow::case::action::execute \
            -no_notification=$no_notification_p \
            -case_id $case_id \
            -action_id $initial_action_id \
            -comment $comment \
            -comment_mime_type $comment_mime_type \
            -user_id $user_id \
            -initial
    }
        
    return $case_id
}

ad_proc -public workflow::case::get_id {
    {-object_id:required}
    {-workflow_short_name:required}
} {
    Gets the case_id from the object_id which the case is about, 
    along with the short_name of the workflow.

    @param object_id The object_id which the case is about
    @param workflow_short_name The short_name of the workflow.
    @return The case_id of the case. Returns the empty string if no case could be found.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set found_p [db_0or1row select_case_id {}]
    if { $found_p } {
        return $case_id
    } else {
        error "No matching workflow case found for object_id $object_id and workflow_short_name $workflow_short_name"
    }
}

ad_proc -public workflow::case::get {
    {-case_id:required}
    {-array:required}
    {-action_id {}}
} {
    Get information about a case. Implemented by workflow::case::fsm::get, because we do not yet 
    support multiple workflow engines.

    @param case_id     The case ID
    @param array       The name of an array in which information will be returned.
    @param action_id   If specified, will return the case information as if the given action had already been executed. 
                       This is useful for presenting forms for actions that do not take place until the user hits OK.

    @author Lars Pind (lars@collaboraid.biz)

    @see workflow::case::fsm::get
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    workflow::case::fsm::get -case_id $case_id -array row -action_id $action_id

    # TODO: Should we redesign the API so that it's polymorphic, wrt. to workflow type (FSM/Petri Net)
    # That way, you'd call workflow::case::get and get a state_pretty pseudocolumn, which would be
    # the pretty-name of the state in an FSM, but it would be some kind of human-readable summary of
    # the active tokens in a petri net.
}

ad_proc -public workflow::case::active_p {
    -case_id:required
} {
    Returns true if the case is active, otherwise false.
} {
    # Implementation note: The case is active if there are any enabled actions, otherwise not
    db_transaction {
        set enabled_actions [workflow::case::get_enabled_actions -case_id $case_id]
    }
    
    return [expr [llength $enabled_actions] > 0]
}

ad_proc -public workflow::case::get_element {
    {-case_id:required}
    {-element:required}
    {-action_id {}}
} {
    Return a single element from the information about a case.

    @param case_id     The ID of the case
    @param element     The element you want
    @param action_id   If specified, will return the case information as if the given action had already been executed. 
                       This is useful for presenting forms for actions that do not take place until the user hits OK.

    @return            The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    get -case_id $case_id -action_id $action_id -array row
    return $row($element)
}

ad_proc -public workflow::case::delete {
    {-case_id:required}
} {
    Delete a workflow case.

    @param case_id The case_id you wish to delete

    @author Simon Carstensen (simon@collaboraid.biz)
} {
    db_exec_plsql delete_case {}
}

ad_proc -public workflow::case::get_user_roles {
    {-case_id:required}
    -user_id
} {
    Get the roles which this user is assigned to. 
    Takes deputies into account, so that if the user is a deputy for someone else, 
    he or she will have the roles of the user for whom he/she is a deputy.

    @param case_id     The ID of the case.
    @param user_id     The user_id of the user for which you want to know the roles. Defaults to ad_conn user_id.
    @return            A list of role_id's of the roles which the user is assigned to in this case.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }
    return [util_memoize [list workflow::case::get_user_roles_not_cached $case_id $user_id] \
                [workflow::case::cache_timeout]]
}

ad_proc -private workflow::case::get_user_roles_not_cached { case_id user_id } {
    Used internally by the workflow Tcl API only. Goes to the database
    to retrieve roles that user is assigned to.

    @author Peter Marklund
} {
    return [db_list select_user_roles {}]
}

ad_proc -public -deprecated workflow::case::get_enabled_actions {
    {-case_id:required}
} {
    Get the currently enabled user actions, based on the state of the case

    @param case_id     The ID of the case.

    @return            A list of action_id's of the actions which are currently 
                       enabled
                       
    @author Lars Pind (lars@collaboraid.biz)

    @see workflow::case::get_enabled_action_ids
} {
    return [util_memoize [list workflow::case::get_enabled_actions_not_cached $case_id] \
                [workflow::case::cache_timeout]]
}

ad_proc -private -deprecated workflow::case::get_enabled_actions_not_cached { case_id } {
    Used internally by the workflow API only. Goes to the database to
    get the enabled actions for the case.
} {
    return [db_list select_enabled_actions {}]
}

ad_proc -public workflow::case::get_enabled_action_ids {
    {-case_id:required}
    {-trigger_type {user}}
} {
    Get the currently enabled_action_id's of enabled user actions in the case.

    Note, that this is different from get_enabled_actions, which only returns 
    the action_id, which will not work for dynamic actions.

    @param case_id       The ID of the case.
    
    @param trigger_type  You can limit to e.g. user actions here. Defaults to user actions. 
                         Specify the empty string if you want all actions.

    @return              A list of currently available enabled_action_id's. 

                       
    @author Lars Pind (lars@collaboraid.biz)
} {
    return [util_memoize [list workflow::case::get_enabled_action_ids_not_cached $case_id $trigger_type] \
                [workflow::case::cache_timeout]]
}

ad_proc -public workflow::case::get_enabled_action_ids_not_cached { 
    case_id
    {trigger_type {}} 
} {
    Used internally by the workflow API only. Goes to the database to
    get the enabled actions for the case.
} {
    if { [empty_string_p $trigger_type] } {
        return [db_list select_enabled_actions {
            select ena.enabled_action_id
            from   workflow_case_enabled_actions ena
            where  ena.case_id = :case_id
            and    ena.completed_p = 'f'
        }]
    } else {
        return [db_list select_enabled_actions {
            select ena.enabled_action_id
            from   workflow_case_enabled_actions ena,
                   workflow_actions a
            where  ena.case_id = :case_id
            and    a.action_id = ena.action_id
            and    ena.completed_p = 'f'
            and    a.trigger_type = 'user'
            order  by a.sort_order
        }]
    }
}

ad_proc -public -deprecated workflow::case::get_available_actions {
    {-case_id:required}
    -user_id
} {
    Get the actions which are enabled and which the current user have permission to execute.

    @param case_id     The ID of the case.
    @return            A list of ID's of the available actions.

    @author Lars Pind (lars@collaboraid.biz)

    @see workflow::case::get_available_enabled_action_ids
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }

    set action_list [list]

    foreach enabled_action_id [workflow::case::get_enabled_action_ids -case_id $case_id] {
        if { [workflow::case::action::permission_p -enabled_action_id $enabled_action_id -user_id $user_id] } {
            lappend action_list [workflow::case::enabled_action_get_element \
                                     -enabled_action_id $enabled_action_id \
                                     -element action_id]
        }
    }

    return $action_list
}

ad_proc -public workflow::case::get_available_enabled_action_ids {
    {-case_id:required}
    -user_id
} {
    Get the enabled_action_id's of the actions available to the given user.

    @param case_id     The ID of the case.

    @return            A list of ID's of the available actions.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }

    set action_list [list]

    foreach enabled_action_id [get_enabled_action_ids -case_id $case_id] {
        if { [workflow::case::action::permission_p -enabled_action_id $enabled_action_id -user_id $user_id] } {
            lappend action_list $enabled_action_id
        }
    }

    return $action_list
}

ad_proc -private workflow::case::assign_roles {
    {-case_id:required}
    {-all:boolean}
} {
    Find out which roles are assigned to currently enabled actions.
    If any of these currently have zero assignees, run the default 
    assignment process.
    
    @param case_id         The ID of the case.
    
    @param all             Set this to assign all roles for this case. 
                           This parameter is deprecated, and always assumed.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set role_ids [db_list select_unassigned_roles {
        select r.role_id
        from   workflow_roles r,
               workflow_cases c
        where  c.case_id = :case_id
        and    r.workflow_id = c.workflow_id
        and    not exists (select 1
                           from   workflow_case_role_party_map m
                           where  m.role_id = r.role_id
                           and    m.case_id = :case_id)
    }]

    foreach role_id $role_ids {
        workflow::case::role::set_default_assignees \
            -case_id $case_id \
            -role_id $role_id
    }

    workflow::case::role::flush_cache -case_id $case_id
}

ad_proc -private workflow::case::get_activity_html { 
    {-case_id:required}
    {-action_id ""}
    {-max_n_actions ""}
    {-style "activity-entry"}
} {
    Get the activity log for a case as an HTML chunk.
    If action_id is non-empty, it means that we're in 
    the progress of executing that action, and the 
    corresponding line for the current action will be appended.

    @param case_id The case for which you want the activity log.
    @param action_id optional action which is currently being executed.
    @param max_n_actions Limit history to the max_n_actions number of most recent actions
    @return Activity log as HTML

    @author Lars Pind (lars@collaboraid.biz)
} {
    set default_file_stub [file join [acs_package_root_dir "workflow"] lib activity-entry]
    set file_stub [template::util::url_to_file $style $default_file_stub]
    if { ![file exists "${file_stub}.adp"] } {
        ns_log Warning "workflow::case::get_activity_html: Cannot find log entry template file $file_stub, reverting to default template."
        # We always have a template named 'activity-entry'
        set file_stub $default_file_stub
    }
    
    # ensure that the style template has been compiled and is up-to-date
    template::adp_init adp $file_stub

    set activity_entry_list [get_activity_log_info_not_cached -case_id $case_id]
    set start_index 0
    if { ![empty_string_p $max_n_actions] && [llength $activity_entry_list] > $max_n_actions} { 
	# Only return the last max_n_actions actions
	set start_index [expr [llength $activity_entry_list] - $max_n_actions]
    } 

    set log_html {}

    foreach entry_arraylist [lrange $activity_entry_list $start_index end] {
        foreach { var value } $entry_arraylist {
            set $var $value
        }

        set comment_html [ad_html_text_convert -from $comment_mime_type -to "text/html" -- $comment] 
        set community_member_url [acs_community_member_url -user_id $creation_user]

        # The output of this procedure will be placed in __adp_output in this stack frame.
        template::code::adp::$file_stub
        append log_html $__adp_output
    }

    if { ![empty_string_p $action_id] } {
        set action_pretty_past_tense [workflow::action::get_element -action_id $action_id -element pretty_past_tense]

        # sets first_names, last_name, email
        acs_user::get -user_id [ad_conn untrusted_user_id] -array user

        set creation_date_pretty [clock format [clock seconds] -format "%m/%d/%Y"]
        # Get rid of leading zeros
        regsub {^0} $creation_date_pretty {} creation_date_pretty
        regsub {/0} $creation_date_pretty {/} creation_date_pretty

        set comment_html {}
        set user_first_names $user(first_names)
        set user_last_name $user(last_name)
        
        set community_member_url [acs_community_member_url -user_id [ad_conn untrusted_user_id]]

        # The output of this procedure will be placed in __adp_output in this stack frame.
        template::code::adp::$file_stub
        append log_html $__adp_output
    }

    return $log_html
}

ad_proc -private workflow::case::get_activity_text { 
    {-case_id:required}
} {
    Get the activity log for a case as a text chunk

    @author Lars Pind
} {
    set log_text {}

    foreach entry_arraylist [get_activity_log_info -case_id $case_id] {
        foreach { var value } $entry_arraylist {
            set $var $value
        }

        set entry_text "$creation_date_pretty $action_pretty_past_tense [ad_decode $log_title "" "" "$log_title "]by $user_first_names $user_last_name ($user_email)"

        if { ![empty_string_p $comment] } {
            append entry_text ":\n\n    [join [split [ad_html_text_convert -from $comment_mime_type -to "text/plain" -maxlen 66 -- $comment] "\n"] "\n    "]"
        }

        lappend log_text $entry_text

        
    }
    return [join $log_text "\n\n"]
}

ad_proc -private workflow::case::get_activity_log_info { 
    {-case_id:required}
} {
    Get the data for the case activity log.

    @return a list of array-lists with the following entries:    
    comment comment_mime_type creation_date_pretty action_pretty_past_tense log_title 
    user_first_names user_last_name user_email creation_user data_arraylist

    @author Lars Pind
} {
    global __cache__workflow__case__get_activity_log_info
    if { ![info exists __cache__workflow__case__get_activity_log_info] } {
        set __cache__workflow__case__get_activity_log_info [get_activity_log_info_not_cached -case_id $case_id]
    }
    return $__cache__workflow__case__get_activity_log_info
}

ad_proc -private workflow::case::get_activity_log_info_not_cached { 
    {-case_id:required}
} {
    Get the data for the case activity log. This version is cached for a single thread.

    @return a list of array-lists with the following entries:    
    comment comment_mime_type creation_date_pretty action_pretty_past_tense log_title 
    user_first_names user_last_name user_email creation_user data_arraylist

    @author Lars Pind
} {
    set workflow_id [workflow::case::get_element -case_id $case_id -element workflow_id]
    set object_id [workflow::case::get_element -case_id $case_id -element object_id]
    set contract_name [workflow::service_contract::activity_log_format_title]
    
    # Get the name of any title Tcl callback proc
    set impl_names [workflow::get_callbacks \
            -workflow_id $workflow_id \
            -contract_name $contract_name]

    # First, we build up a multirow so we have all the data in memory, which lets us peek ahead at the contents
    db_multirow -extend {comment} -local entries select_log {} {
       set comment $comment_string
       set action_pretty_past_tense [lang::util::localize $action_pretty_past_tense]
    }

    
    set rowcount [template::multirow -local size entries]

    set counter 1

    set last_entry_id {}
    set data_arraylist [list]

    # Then iterate over the multirow to build up the activity log HTML
    # We need to peek ahead, because this is an outer join to get the rows in workflow_case_log_data

    set entries [list]
    template::multirow -local foreach entries {

        if { ![empty_string_p $key] } {
            lappend data_arraylist $key $value
        }

        if { $counter == $rowcount || ![string equal $last_entry_id [set "entries:[expr $counter + 1](entry_id)"]] } {
            
            set log_title_elements [list]
            foreach impl_name $impl_names {
                set result [acs_sc::invoke \
                                -contract $contract_name \
                                -operation "GetTitle" \
                                -impl $impl_name \
                                -call_args [list $case_id $object_id $action_id $entry_id $data_arraylist]]
                if { ![empty_string_p $result] } {
                    lappend log_title_elements $result
                }
            }
            set log_title [ad_decode [llength $log_title_elements] 0 "" "([join $log_title_elements ", "])"]
            
            set row [list]
            foreach var { 
                comment comment_mime_type creation_date_pretty action_pretty_past_tense log_title 
                user_first_names user_last_name user_email creation_user data_arraylist
            } {
                lappend row $var [set $var]
            }
            lappend entries $row

            set data_arraylist [list]
        }
        set last_entry_id $entry_id
        incr counter
    }

    return $entries
}

ad_proc workflow::case::get_notification_object {
    {-type:required}
    {-workflow_id ""}
    {-case_id ""}
} {
    Get the relevant object for this notification type.

    @param type Type is one of 'workflow_assignee', 'workflow_my_cases',
    'workflow_case' (requires case_id), and 'workflow' (requires
    workflow_id).
} {
    switch $type {
        workflow_case {
            if { ![exists_and_not_null case_id] } {
                return {}
            }
            return [workflow::case::get_element -case_id $case_id -element object_id]
        }
        default {
            if { ![exists_and_not_null workflow_id] } {
                return {}
            }
            return [workflow::get_element -workflow_id $workflow_id -element object_id]
        }
    }
}

ad_proc workflow::case::get_notification_request_url {
    {-type:required}
    {-workflow_id ""}
    {-case_id ""}
    {-return_url ""}
    {-pretty_name ""}
} {
    Get the URL to subscribe to notifications

    @param type Type is one of 'workflow_assignee', 'workflow_my_cases',
    'workflow_case' (requires case_id), and 'workflow' (requires
    workflow_id).
} {
    if { [ad_conn user_id] == 0 } {
        return {}
    }
    
    set object_id [get_notification_object \
            -type $type \
            -workflow_id $workflow_id \
            -case_id $case_id]

    if { [empty_string_p $object_id] } {
        return {}
    }

    if { ![exists_and_not_null return_url] } {
        set return_url [ad_return_url]
    }

    set url [notification::display::subscribe_url \
            -type $type \
            -object_id  $object_id \
            -url $return_url \
            -user_id [ad_conn user_id] \
            -pretty_name $pretty_name]
    
    return $url
}

ad_proc workflow::case::get_notification_requests_multirow {
    {-multirow_name:required}
    {-label ""}
    {-workflow_id ""}
    {-case_id ""}
    {-return_url ""}
} {
    Returns a multirow with columns url, label, title, 
    of the possible workflow notification types. Use this to present the user with a list of 
    subscription links.
} {
    array set pretty {
        workflow_assignee {my actions}
        workflow_my_cases {my cases}
        workflow_case {this case}
        workflow {cases in this workflow}
    }

    template::multirow create $multirow_name url label title
    foreach type { 
        workflow_assignee workflow_my_cases workflow_case workflow
    } {
        set url [get_notification_request_url \
                -type $type \
                -workflow_id $workflow_id \
                -case_id $case_id \
                -return_url $return_url]

        if { ![empty_string_p $url] } {
            set title "Subscribe to $pretty($type)"
            if { ![empty_string_p $label] } {
                set row_label $label
            } else {
                set row_label $title
            }
            template::multirow append $multirow_name $url $row_label $title
        }
    }
}

ad_proc workflow::case::add_log_data {
    {-entry_id:required}
    {-key:required}
    {-value:required}
} {
    Adds extra data information to a log entry, which can later
    be retrieved using workflow::case::get_log_data_by_key.
    Data are stored as simple key/value pairs.
    
    @param entry_id The ID of the log entry to which you want to attach data.
    @param key The data key.
    @param value The data value
    
    @see workflow::case::get_log_data_by_key
    @see workflow::case::get_log_data
    @author Lars Pind (lars@collaboraid.biz)
} {
    db_dml insert_log_data {}
}

ad_proc workflow::case::get_log_data_by_key {
    {-entry_id:required}
    {-key:required}
} {
    Retrieve extra data for a workflow log entry, previously stored using workflow::case::add_log_data.

    @param entry_id The ID of the log entry to which the data you want are attached.
    @param key The key of the data you're looking for.
    @return The value, or the empty string if no such key exists for this entry.

    @see workflow::case::add_log_data
    @see workflow::case::get_log_data
    @author Lars Pind (lars@collaboraid.biz)
} {
    db_string select_log_data {} -default {}
}

ad_proc workflow::case::get_log_data {
    {-entry_id:required}
} {
    Retrieve extra data for a workflow log entry, previously stored using workflow::case::add_log_data.

    @param entry_id The ID of the log entry to which the data you want are attached.
    @return A tcl list of key/value pairs in array-list format, i.e. { key1 value1 key2 value2 ... }.

    @see workflow::case::add_log_data
    @see workflow::case::get_log_data_by_key
    @author Lars Pind (lars@collaboraid.biz)
} {
    db_string select_log_data {} -default {}
}

ad_proc -private workflow::case::cache_timeout {} {
    Number of seconds before we timeout the case level workflow cache.

    @author Peter Marklund
} {
    # 60 * 60 seconds is 1 hour
    return 3600
}

ad_proc -private workflow::case::flush_cache { 
    {-case_id ""}
} {
    Flush all cached data for a given case or for all
    cases if none is specified.

    @param case_id The id of the workflow case to flush. If not provided the
                   cache will be flushed for all workflow cases.

    @author Peter Marklund
} {
    foreach proc_name {
        workflow::case::fsm::get_info_not_cached
        workflow::case::get_user_roles_not_cached
        workflow::case::get_enabled_actions_not_cached
        workflow::case::get_enabled_action_ids_not_cached
    } {
        util_memoize_flush_regexp "^$proc_name [ad_decode $case_id "" {\.*} $case_id]"
    }

    util_memoize_flush_regexp [list workflow::case::get_activity_log_info_not_cached -case_id $case_id]

    # Flush role info (assignees etc)
    workflow::case::role::flush_cache -case_id $case_id
}


ad_proc -public workflow::case::timed_actions_sweeper {} {
    Sweep for timed actions ready to fire.
} {
    set enabled_action_ids [db_list select_timed_out_actions {}]
    
    foreach enabled_action_id $enabled_action_ids {
        workflow::case::action::execute \
            -no_perm_check \
            -enabled_action_id $enabled_action_id
    }
}

ad_proc -public workflow::case::enabled_action_get {
    {-enabled_action_id:required}
    {-array:required}
} {
    Get information about an enabled action

    @param array       The name of an array in which information will be returned.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    db_1row select_enabled_action {} -column_array row
}

ad_proc -public workflow::case::enabled_action_get_element {
    {-enabled_action_id:required}
    {-element:required}
} {
    Return a single element from the information about an enabled action

    @param element     The element you want
    @return            The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    enabled_action_get -enabled_action_id $enabled_action_id -array row
    return $row($element)
}

#####
#
# workflow::case::role namespace
#
#####

ad_proc -public workflow::case::role::set_default_assignees {
    {-case_id:required}
    {-role_id:required}
} {
    Find the default assignee for this role.
    
    @param case_id the ID of the case.
    @param role_id the ID of the role to assign.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set contract_name [workflow::service_contract::role_default_assignees]

    db_transaction {

        set impl_names [workflow::role::get_callbacks \
                -role_id $role_id \
                -contract_name $contract_name]
        
        set object_id [workflow::case::get_element -case_id $case_id -element object_id]
        
        foreach impl_name $impl_names {
            # Call the service contract implementation
            set party_id_list [acs_sc::invoke \
                    -contract $contract_name \
                    -operation "GetAssignees" \
                    -impl $impl_name \
                    -call_args [list $case_id $object_id $role_id]]
    
            if { [llength $party_id_list] != 0 } {
                assignee_insert -case_id $case_id -role_id $role_id -party_ids $party_id_list

                # We stop when the first callback returned something
                break
            }
        }
    }
}

ad_proc -public workflow::case::role::get_picklist {
    {-case_id:required}
    {-role_id:required}
} {
    Get the picklist for this role.

    @param case_id the ID of the case.
    @param role_id the ID of the role.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set contract_name [workflow::service_contract::role_assignee_pick_list]

    set party_id_list [list]

    db_transaction {

        set impl_names [workflow::role::get_callbacks \
                -role_id $role_id \
                -contract_name $contract_name]

        set object_id [workflow::case::get_element -case_id $case_id -element object_id]

        foreach impl_name $impl_names {
            # Call the service contract implementation
            set party_id_list [acs_sc::invoke \
                    -contract $contract_name \
                    -operation "GetPickList" \
                    -impl $impl_name \
                    -call_args [list $case_id $object_id $role_id]]
    
            if { [llength $party_id_list] != 0 } {
                # Return after the first non-empty list
                break
            }
        }
    }

    if { [ad_conn isconnected] && [ad_conn user_id] != 0 } {
        lappend party_id_list [ad_conn user_id]
    }

    if { [llength $party_id_list] > 0 } { 
        set options [db_list_of_lists select_options {}]
    } else {
        set options {}
    }

    set options [concat { { "Unassigned" "" } } $options]
    lappend options { "Search..." ":search:"}

    return $options
}

ad_proc -public workflow::case::role::get_search_query {
    {-case_id:required}
    {-role_id:required}
} {
    Get the search query for this role.

    @param case_id the ID of the case.
    @param role_id the ID of the role.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set contract_name [workflow::service_contract::role_assignee_subquery]

    set impl_names [workflow::role::get_callbacks \
            -role_id $role_id \
            -contract_name $contract_name]
    
    set object_id [workflow::case::get_element -case_id $case_id -element object_id]

    set subquery {}
    foreach impl_name $impl_names {
        # Call the service contract implementation
        set subquery [acs_sc::invoke \
                -contract $contract_name \
                -operation "GetSubquery" \
                -impl $impl_name \
                -call_args [list $case_id $object_id $role_id]]

        if { ![empty_string_p $subquery] } {
            # Return after the first non-empty list
            break
        }
    }

    return [db_map select_search_results]

    
}

ad_proc -public workflow::case::role::get_assignee_widget {
    {-case_id:required}
    {-role_id:required}
    {-prefix "role_"}
} {
    Get the assignee widget for use with ad_form for this role.

    @param case_id the ID of the case.
    @param role_id the ID of the role.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set workflow_id [workflow::case::get_element -case_id $case_id -element workflow_id]

    workflow::role::get -role_id $role_id -array role
    set element "${prefix}$role(short_name)"
    
    set query [workflow::case::role::get_search_query -case_id $case_id -role_id $role_id]
    set picklist [workflow::case::role::get_picklist -case_id $case_id -role_id $role_id]
    
    return [list "${element}:search(search),optional" [list label $role(pretty_name)] [list mode display] \
            [list search_query $query] [list options $picklist]]
}

ad_proc -public workflow::case::role::add_assignee_widgets {
    {-case_id:required}
    {-form_name:required}
    {-prefix "role_"}
} {
    Get the assignee widget for use with ad_form for this role.

    @param case_id the ID of the case.
    @param role_id the ID of the role.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set workflow_id [workflow::case::get_element -case_id $case_id -element workflow_id]
    set roles [list]
    foreach role_id [workflow::get_roles -workflow_id $workflow_id] {
        ad_form -extend -name $form_name -form [list [get_assignee_widget -case_id $case_id -role_id $role_id -prefix $prefix]]
    }
}

ad_proc -public workflow::case::role::set_assignee_values {
    {-case_id:required}
    {-form_name:required}
    {-prefix "role_"}
} {
    Get the assignee widget for use with ad_form for this role.

    @param case_id the ID of the case.
    @param role_id the ID of the role.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set workflow_id [workflow::case::get_element -case_id $case_id -element workflow_id]

    # Set role assignee values
    foreach role_id [workflow::get_roles -workflow_id $workflow_id] {
        workflow::role::get -role_id $role_id -array role
        set element "${prefix}$role(short_name)"

        # HACK: Only care about the first assignee
        set assignees [workflow::case::role::get_assignees -case_id $case_id -role_id $role_id]
        if { [llength $assignees] == 0 } {
            array set cur_assignee { party_id {} name {} email {} }
        } else {
            array set cur_assignee [lindex $assignees 0]
        }

        if { [uplevel info exists $form_name:$element] } {
            # Set normal value
            if { [uplevel template::form is_request $form_name] || [string equal [uplevel [list element get_property $form_name $element mode]] "display"] } {
                uplevel [list element set_value $form_name $element $cur_assignee(party_id)]
            }
            
            # Set display value
            if { [empty_string_p $cur_assignee(party_id)] } {
                set display_value "<i>None</i>"
            } else {
                set display_value [acs_community_member_link \
                        -user_id $cur_assignee(party_id) \
                        -label $cur_assignee(name)] 
                if { [ad_conn user_id] != 0 } {
                    append display_value " (<a href=\"mailto:$cur_assignee(email)\">$cur_assignee(email)</a>)"
                } else {
		    append display_value " ([string replace $cur_assignee(email) \
			    [expr [string first "@" $cur_assignee(email)]+3] end "..."])"
		}
            }

            uplevel [list element set_properties $form_name $element -display_value $display_value]
        }
    }
}

ad_proc -public workflow::case::role::get_assignees {
    {-case_id:required}
    {-role_id:required}
} {
    Get the current assignees for a role in a case as a list of 
    [array get]'s of party_id, email, name.

    @param case_id the ID of the case.
    @param role_id the ID of the role.
    @return a list of 
    [array get]'s of party_id, email, name.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [util_memoize [list workflow::case::role::get_assignees_not_cached $case_id $role_id] \
                [workflow::case::cache_timeout]]
}

ad_proc -private workflow::case::role::get_assignees_not_cached { case_id role_id } {
    Proc used only internally by the workflow API. Retrieves role assignees
    directly from the database.

    @author Peter Marklund
} {
    set result {}
    db_foreach select_assignees {} -column_array row {
        lappend result [array get row]
    }
    return $result    
}

ad_proc -private workflow::case::role::flush_cache { 
    {-case_id ""}
 } {
    Flush all role related info for a certain case or for all
    cases if none is specified.
} {
    util_memoize_flush_regexp "^workflow::case::role::get_assignees_not_cached [ad_decode $case_id "" {\.*} $case_id]"
}

ad_proc -public workflow::case::role::assignee_insert {
    {-case_id:required}
    {-role_id:required}
    {-party_ids:required}
    {-replace:boolean}
} {
    Insert a new assignee for this role
    
    @param case_id the ID of the case.
    @param role_id the ID of the role to assign.
    @param party_id the ID of party to assign to this role

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_transaction { 
        if { $replace_p } {
            db_dml delete_assignees {}
        }
        
        foreach party_id $party_ids {
            if { [catch {
                db_dml insert_assignee {}
            } errMsg] } {
                set already_assigned_p [db_string already_assigned_p {}]
                if { !$already_assigned_p } {
                    global errorInfo errorCode
                    error $errMsg $errorInfo $errorCode
                }
            }
        }
    }

    workflow::case::role::flush_cache -case_id $case_id
}

ad_proc -public workflow::case::role::assignee_remove {
    {-case_id:required}
    {-role_id:required}
    {-party_id:required}
} {
    Remove an assignee from this role
    
    @param case_id the ID of the case.
    @param role_id the ID of the role to remove the assignee from.
    @param party_id the ID of party to remove from the role

    @author Peter Marklund
} {
    db_dml delete_assignee {}

    workflow::case::role::flush_cache -case_id $case_id
}

ad_proc -public workflow::case::role::assign {
    {-case_id:required}
    {-array:required}
    {-replace:boolean}
} {
    Assign roles from an array with entries like this: array(short_name) = [list of party_ids].
    
    @param case_id The ID of the case.
    @param array Name of array with assignment info 
    @param replace Should the new assignees replace existing assignees?

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar $array assignees

    set workflow_id [workflow::case::get_element -case_id $case_id -element workflow_id]
    
    db_transaction {
        foreach name [array names assignees] {
            
            set role_id [workflow::role::get_id \
                             -workflow_id $workflow_id \
                             -short_name $name]
            
            workflow::case::role::assignee_insert \
                -replace=$replace_p \
                -case_id $case_id \
                -role_id $role_id \
                -party_ids $assignees($name)
        }
    }
}




#####
#
# workflow::case::fsm
#
#####

ad_proc -public workflow::case::fsm::get_current_state {
    {-case_id:required}
} {
    Gets the current state_id of this case.

    @param case_id The case_id.
    @return The state_id of the state which this case is in

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [workflow::case::fsm::get_element -case_id $case_id -element state_id]
}

ad_proc -public workflow::case::fsm::get {
    {-case_id:required}
    {-array:required}
    {-parent_enabled_action_id {}}
    {-action_id {}}
    {-enabled_action_id {}}
} {
    Get information about an FSM case set as values in your array. 
    case_id state_short_name pretty_state state_hide_fields state_id parent_enabled_action_id parent_case_id 
    entry_id top_case_id workflow_id object_id

    @param case_id     The ID of the case

    @param array       The name of an array in which information will be returned.

    @param parent_enabled_action_id   
                       If specified, will return the sub-case information for the given action.

    @param action_id   Deprecated. Same effect as enabled_action_id, but will not work for dynamic workflows.

    @param enabled_action_id 
                       If specified, will return the case information as if the given action had already
                       been executed. This is useful for presenting forms for actions that do not take place
                       until the user hits OK.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    if { ![empty_string_p $action_id] } {
        if { ![empty_string_p $enabled_action_id] } {
            error "You cannot specify both action_id and enabled_action_id. enabled_action_id is preferred."
        }
        set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                   -case_id $case_id \
                                   -action_id $action_id \
                                   -any_parent]
    }

    if { [empty_string_p $enabled_action_id] } {
        array set row [util_memoize [list workflow::case::fsm::get_info_not_cached $case_id $parent_enabled_action_id] \
                           [workflow::case::cache_timeout]]
        set row(entry_id) {}
    } else {
        # TODO: cache this query as well
        db_1row select_case_info_after_action {} -column_array row
        set row(entry_id) [db_nextval "acs_object_id_seq"]
    }
}

ad_proc -public workflow::case::fsm::get_element {
    {-case_id:required}
    {-element:required}
    {-parent_enabled_action_id {}}
    {-action_id {}}
} {
    Return a single element from the information about a case.

    @param case_id     The ID of the case
    @param element     The element you want
    @param action_id   If specified, will return the case information as if the given action had already been executed. 
                       This is useful for presenting forms for actions that do not take place until the user hits OK.

    @return            The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    get -case_id $case_id -parent_enabled_action_id $parent_enabled_action_id -action_id $action_id -array row
    return $row($element)
}

ad_proc -private workflow::case::fsm::get_info_not_cached { case_id { parent_enabled_action_id "" } } {
    Used internally by the workflow id to get FSM case info from the
    database.

    @author Peter Marklund
} {
    if { [empty_string_p $parent_enabled_action_id] } {
        db_1row select_case_info_null_parent_id {} -column_array row
    } else {
        db_1row select_case_info {} -column_array row
    }

    return [array get row]
}

ad_proc -private workflow::case::fsm::get_state_info { 
    -case_id:required
    {-parent_enabled_action_id {}}
    {-all:boolean}
 } {
    Gets all state info from the database, include sub-action state.

    @return a list of (action_id, current_state) tuples. 
    The top-level state is the one that has action_id empty.
} {
    # TODO: Cache and flush
    return [workflow::case::fsm::get_state_info_not_cached $case_id $parent_enabled_action_id $all_p]
}

ad_proc -private workflow::case::fsm::get_state_info_not_cached { 
    case_id 
    parent_enabled_action_id
    all_p
} {
    Gets all state info from the database, include sub-action state.

    @return a list of (action_id, current_state) tuples. 
    The top-level state is the one that has action_id empty.

    @see workflow::case::fsm::get_state_info
} {
    if { $all_p  } {
        return [db_list_of_lists select_state_info {}]
    } else {
        if { [empty_string_p $parent_enabled_action_id] } {
            return [db_string null_parent {
                select current_state
                from   workflow_case_fsm
                where  case_id = :case_id
                and    parent_enabled_action_id is null
            }]
        } else {
            return [db_string null_parent {
                select current_state
                from   workflow_case_fsm
                where  case_id = :case_id
                and    parent_enabled_action_id = :parent_enabled_action_id
            }]
        }
    }
}


#####
#
# workflow::case::action 
#
#####

ad_proc -public workflow::case::action::permission_p {
    {-enabled_action_id {}}
    {-case_id {}}
    {-action_id {}}
    {-user_id}
} {
    Does the user have permission to perform this action. Doesn't
    check whether the action is enabled.

    @param enabled_action_id  The enabled action you want to test for permission on.

    @param case_id            Deprecated. The ID of the case.

    @param action_id          Deprecated. The ID of the action

    @param user_id            The user.

    @return true or false.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }

    if { ![empty_string_p $enabled_action_id] } {
        workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
        set case_id $enabled_action(case_id)
        set action_id $enabled_action(action_id)
    } else {
        set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                   -any_parent \
                                   -case_id $case_id \
                                   -action_id $action_id]
    }

    set object_id [workflow::case::get_element -case_id $case_id -element object_id]
    set user_role_ids [workflow::case::get_user_roles -case_id $case_id -user_id $user_id]

    set permission_p 0

    set assigned_p [db_string assigned_p {
        select 1 
        from   wf_case_assigned_user_actions
        where  enabled_action_id = :enabled_action_id
        and    user_id = :user_id
    } -default 0]
    
    if { $assigned_p } {
        return 1
    }

    foreach role_id $user_role_ids {


        # Is this an allowed role for this action?
        set allowed_roles [workflow::action::get_allowed_roles -action_id $action_id]
        if { [lsearch $allowed_roles $role_id] != -1 } {
            return 1
        }
    }

    if { !$permission_p } {
        set privileges [concat "admin" [workflow::action::get_privileges -action_id $action_id]]
        foreach privilege $privileges {
            if { [permission::permission_p -object_id $object_id -privilege $privilege -party_id $user_id] } {
                return 1
            }
        }
    }

    return 0
}

ad_proc -public workflow::case::action::enabled_p {
    {-case_id:required}
    {-action_id:required}
} {
    Is this action currently enabled.

    @param case_id            The ID of the case.

    @param action_id          The ID of the action

    @return true or false.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [db_string select_enabled_p {} -default 0]
}

ad_proc -public workflow::case::action::available_p {
    {-enabled_action_id {}}
    {-case_id {}}
    {-action_id {}}
    {-user_id {}}
} {
    Is this action currently enabled and does the user have permission to perform it?

    @param enabled_action_id  The enabled action you want to test for permission on.

    @param case_id            Deprecated. The ID of the case.

    @param action_id          Deprecated. The ID of the action

    @param user_id            The user.

    @return true or false.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Always permit the no-op
    if { [empty_string_p $action_id] && [empty_string_p $enabled_action_id] } {
        return 1
    }

    if { ![empty_string_p $enabled_action_id] } {
        workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
        set case_id $enabled_action(case_id)
        set action_id $enabled_action(action_id)
    } else {
        set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                   -any_parent \
                                   -case_id $case_id \
                                   -action_id $action_id]
    }

    if { [workflow::case::action::enabled_p -case_id $case_id -action_id $action_id] &&
         [workflow::case::action::permission_p -enabled_action_id $enabled_action_id -user_id $user_id] } {
        return 1
    } else {
        return 0
    }
}


ad_proc -private workflow::case::action::get_enabled_action_id {
    {-case_id:required}
    {-action_id:required}
    {-parent_enabled_action_id {}}
    {-all:boolean}
    {-any_parent:boolean}
} {
    Get the enabled_action_id from case_id and action_id. Doesn't find completed enabled actions.
    Provided for backwards compatibility. Doesn't work properly for dynamic actions.

    @param all If specified, will return all if more than one is found. Otherwise returns just the first.

    @return enabled_action_id. Returns blank if no enabled action exists. 
} {
    if { $any_parent_p } {
        set result [db_list select_enabled_action_id {
            select enabled_action_id
            from   workflow_case_enabled_actions
            where  case_id = :case_id
            and    action_id = :action_id
            and    completed_p = 'f'
        }]
    } else {
        if { [empty_string_p $parent_enabled_action_id] } {
            set result [db_list select_enabled_action_id {
                select enabled_action_id
                from   workflow_case_enabled_actions
                where  case_id = :case_id
                and    action_id = :action_id
                and    completed_p = 'f'
                and    parent_enabled_action_id = :parent_enabled_action_id
            }]
        } else {
            set result [db_list select_enabled_action_id {
                select enabled_action_id
                from   workflow_case_enabled_actions
                where  case_id = :case_id
                and    action_id = :action_id
                and    completed_p = 'f'
                and    parent_enabled_action_id is null
            }]
        }
    }

    if { $all_p } {
        return $result
    } else {
        return [lindex $result 0]
    }
}



ad_proc -public workflow::case::action::do_side_effects {
    {-case_id:required}
    {-action_id:required}
    {-entry_id:required}
} {
    Fire the side-effects for this action
} {
    set contract_name [workflow::service_contract::action_side_effect]

    # Get info for the callbacks
    set workflow_id [workflow::case::get_element \
            -case_id $case_id \
            -element workflow_id]

    # Get the callbacks, workflow and action
    set impl_names [workflow::get_callbacks \
            -workflow_id $workflow_id \
            -contract_name $contract_name]
    
    set impl_names [concat $impl_names [workflow::action::get_callbacks \
            -action_id $action_id \
            -contract_name $contract_name]]

    if { [llength $impl_names] == 0 } {
        return
    }
    
    set object_id [workflow::case::get_element \
            -case_id $case_id \
            -element object_id]

    # Invoke them
    foreach impl_name $impl_names {
        acs_sc::invoke \
                -contract $contract_name \
                -operation "DoSideEffect" \
                -impl $impl_name \
                -call_args [list $case_id $object_id $action_id $entry_id]
    }   
} 
    
ad_proc -public workflow::case::action::notify {
    {-case_id:required}
    {-action_id:required}
    {-entry_id:required}
    {-comment:required}
    {-comment_mime_type:required}
} {
    Send out notifications to relevant people.
} {
    # Get workflow_id
    workflow::case::get \
        -case_id $case_id \
        -array case

    workflow::get \
        -workflow_id $case(workflow_id) \
        -array workflow
    
    set hr [string repeat "=" 70]
    
    # TODO: Get activity log for top-case
    array set latest_action [lindex [workflow::case::get_activity_log_info -case_id $case_id] end]

    # Variables used by I18N messages:
    set action_past_tense "$latest_action(action_pretty_past_tense)[ad_decode $latest_action(log_title) "" "" " $latest_action(log_title)"]"
    set user_name "$latest_action(user_first_names) $latest_action(user_last_name)"
    set user_email $latest_action(user_email)
    set latest_action_chunk [_ workflow.notification_email_latest_action_chunk]
    
    if { ![empty_string_p $latest_action(comment)] } {
        append latest_action_chunk ":\n\n    [join [split [ad_html_text_convert -from $latest_action(comment_mime_type) -to "text/plain" -maxlen 66 -- $latest_action(comment)] "\n"] "\n    "]"
    }
    
    # Callback to get notification info 
    # TODO: Should this be the parent/top-workflow that does this?
    set contract_name [workflow::service_contract::notification_info]
    set impl_names [workflow::get_callbacks \
                        -workflow_id $case(workflow_id) \
                        -contract_name $contract_name]
    # We only use the first callback
    set impl_name [lindex $impl_names 0]
    
    if { ![empty_string_p $impl_name] } {
        set notification_info [acs_sc::invoke \
                                   -contract $contract_name \
                                   -operation "GetNotificationInfo" \
                                   -impl $impl_name \
                                   -call_args [list $case_id $case(object_id)]]
        
    }

    # Make sure the notification info list has at least 4 elements, so we can do below lindex's safely
    lappend notification_info {} {} {} {}
    
    set object_url [lindex $notification_info 0]
    set object_one_line [lindex $notification_info 1]
    set object_details_list [lindex $notification_info 2]
    set object_notification_tag [lindex $notification_info 3]

    if { [empty_string_p $object_one_line] } {
        # Default: Case #$case_id: acs_object__name(case.object_id)

        set object_id $case(object_id)
        db_1row select_object_name {} -column_array case_object

        set object_one_line "[_ workflow.Case] #$case_id: $case_object(name)"
    }

    # Roles and their current assignees
    foreach role_id [workflow::get_roles -workflow_id $case(workflow_id)] {
        set label [workflow::role::get_element -role_id $role_id -element pretty_name]
        foreach assignee_arraylist [workflow::case::role::get_assignees -case_id $case_id -role_id $role_id] {
            array set assignee $assignee_arraylist
            lappend object_details_list $label "$assignee(name) ($assignee(email))"
            set label {}
        }
    }

    # Find the length of the longest label
    set max_label_len 0
    foreach { label value } $object_details_list {
        if { [string length $label] > $max_label_len } {
            set max_label_len [string length $label]
        }
    }
                     
    # Output notification info
    set object_details_lines [list]
    foreach { label value } $object_details_list {
        if { ![empty_string_p $label] } {
            lappend object_details_lines "$label[string repeat " " [expr $max_label_len - [string length $label]]] : $value"
        } else {
            lappend object_details_lines "[string repeat " " $max_label_len]   $value"
        }
    }
    set object_details_chunk [join $object_details_lines "\n"]

    set activity_log_chunk [workflow::case::get_activity_text -case_id $case_id]

    set the_subject "[ad_decode $object_notification_tag "" "" "\[$object_notification_tag\] "]$object_one_line: $latest_action(action_pretty_past_tense) [ad_decode $latest_action(log_title) "" "" "$latest_action(log_title) "]by $latest_action(user_first_names) $latest_action(user_last_name)"

    # List of user_id's for people who are in the assigned_role to any enabled actions
    # This takes deputies into account

#XXXXX Verify this ... probably wrong
    set assignee_list [db_list enabled_action_assignees {}]

    # List of users who play some role in this case
    # This takes deputies into account
    set case_player_list [db_list case_players {}]

    # Get pretty_name and pretty_plural for the case's object type
    set object_id $case(object_id)
    db_1row select_object_type_info {} -column_array object_type

    # Get name of the workflow's object
    set object_id $workflow(object_id)
    db_1row select_object_name {} -column_array workflow_object

    set next_action_chunk(workflow_assignee) [_ workflow.lt_You_are_assigned_to_t]

    set next_action_chunk(workflow_my_cases) [_ workflow.lt_You_are_a_participant]

    set next_action_chunk(workflow_case) [_ workflow.lt_You_have_a_watch_on_t]

    set next_action_chunk(workflow) [_ workflow.lt_You_have_requested_to]

    # Initialize stuff that depends on the notification type
    foreach type { 
        workflow_assignee workflow_my_cases workflow_case workflow
    } {
        set subject($type) $the_subject
        set body($type) "$hr
$object_one_line
$hr

$latest_action_chunk

$hr

$next_action_chunk($type)[ad_decode $object_url "" "" "\n\n[_ workflow.lt_Please_click_here_to_]\n\n$object_url"]

$hr[ad_decode $object_details_chunk "" "" "\n$object_details_chunk\n$hr"]

$activity_log_chunk

$hr
"
        set force_p($type) 0
        set subset($type) {}
    }

    set force_p(workflow_assignee) 1
    set subset(workflow_assignee) $assignee_list
    set subset(workflow_my_cases) $case_player_list
    
    set notified_list [list]

    foreach type { 
        workflow_assignee workflow_my_cases workflow_case workflow
    } {
        set object_id [workflow::case::get_notification_object \
                -type $type \
                -workflow_id $case(workflow_id) \
                -case_id $case_id]

        if { ![empty_string_p $object_id] } {

            set notified_list [concat $notified_list [notification::new \
                    -type_id [notification::type::get_type_id -short_name $type] \
                    -object_id $object_id \
                    -action_id $entry_id \
                    -response_id $case(object_id) \
                    -notif_subject $subject($type) \
                    -notif_text $body($type) \
                    -already_notified $notified_list \
                    -subset $subset($type) \
                    -return_notified]]
        }
    }
}



#######################################################################
#
# WORKFLOW ENGINE PROCS
#
#######################################################################

# Below are all the procs that drive the workflow engine, 
# the logic to change state and determine which actions
# are availble given the current state.

#####
#
# Causing changes to state
#
#####

ad_proc -public workflow::case::action::execute {
    {-no_notification:boolean}
    {-no_perm_check:boolean}
    {-enabled_action_id {}}
    {-case_id {}}
    {-action_id {}}
    {-parent_enabled_action_id {}}
    {-comment ""}
    {-comment_mime_type "text/plain"}
    {-user_id}
    {-initial:boolean}
    {-entry_id {}}
} {
    Execute the action. Either provide (case_id, action_id, parent_enabled_action_id), or simply enabled_action_id.

    @param enabled_action_id  The ID of the enabled action to execute. Alternatively, you can specify the case_id/action_id pair.

    @param case_id            The ID of the case.

    @param action_id          The ID of the action

    @param comment            Comment for the case activity log

    @param comment_mime_type  MIME Type of the comment, according to 
                              OpenACS standard text formatting

    @param user_id            The user who's executing the action

    @param initial            Use this switch to signal that this is the initial action. This causes 
                              permissions/enabled checks to be bypasssed, and causes all roles to get assigned.

    @param entry_id           Optional item_id for double-click protection. If you call workflow::case::fsm::get
                              with a non-empty action_id, it will generate a new entry_id for you, which you can pass in here.

    @param no_perm_check      Set this switch if you do not want any permissions chcecking, e.g. for automatic actions.

    @return entry_id of the new log entry (will be a cr_item).

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![exists_and_not_null user_id] } {
        if { ![ad_conn isconnected] } {
            set user_id 0
        } else {
            set user_id [ad_conn user_id]
        }
    }

    if { [empty_string_p $case_id] || [empty_string_p $action_id] } {
        if { [empty_string_p $enabled_action_id] } {
            error "You must supply either case_id and action_id, or enabled_action_id"
        }
    }
    if { [empty_string_p $enabled_action_id] } {
        if { $initial_p } {
            set enabled_action_id {}
        } else {
            # This will not work with dynamic actions
            # This is provided for backwards-compatibility, so we hope there's no dynamicism
            # TODO: Figure out a better solution to this problem
            set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                       -any_parent \
                                       -case_id $case_id \
                                       -action_id $action_id]
            if { [empty_string_p $enabled_action_id] } {
                error "This action is not enabled at this time."
            }
        }
    }
    if { ![empty_string_p $enabled_action_id] } {
        workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
        set case_id $enabled_action(case_id)
        set action_id $enabled_action(action_id)
        set parent_enabled_action_id $enabled_action(parent_enabled_action_id)
        set parent_trigger_type $enabled_action(parent_trigger_type)
    } else {
        set parent_trigger_type "workflow"
    }

    if { !$initial_p && !$no_perm_check_p } {
        if { ![workflow::case::action::permission_p -enabled_action_id $enabled_action_id -user_id $user_id] } {
            error "This user ($user_id) is not allowed to perform this action ($action_id) at this time."
        }
    }

    if { [empty_string_p $comment] } {
        # single-space comment
        set comment { }
    }

    # We can't have empty comment_mime_type, default to text/plain
    if { [empty_string_p $comment_mime_type] } {
        set comment_mime_type "text/plain"
    }

    db_transaction {

        # Double-click protection
        if { ![empty_string_p $entry_id] } {
            if {  [db_string log_entry_exists_p {}] } {
                return $entry_id
            }
        }
        
        # Update the case workflow state
        workflow::case::action::fsm::execute_state_change \
            -initial=$initial_p \
            -enabled_action_id $enabled_action_id \
            -case_id $case_id \
            -action_id $action_id \
            -parent_enabled_action_id $parent_enabled_action_id

        # Mark the action completed
        if { ![empty_string_p $enabled_action_id] } {
            workflow::case::action::complete \
                -enabled_action_id $enabled_action_id \
                -user_id $user_id
        }

        # Insert activity log entry
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set \
                -ns_set $extra_vars \
                -var_list { entry_id case_id action_id comment comment_mime_type }
        
        set entry_id [package_instantiate_object \
                -creation_user $user_id \
                -extra_vars $extra_vars \
                -package_name "workflow_case_log_entry" \
                "workflow_case_log_entry"]

        # Fire side-effects
        workflow::case::action::do_side_effects \
                -case_id $case_id \
                -action_id $action_id \
                -entry_id $entry_id
        
        # Notifications
        if { !$no_notification_p } {
            workflow::case::action::notify \
                -case_id $case_id \
                -action_id $action_id \
                -entry_id $entry_id \
                -comment $comment \
                -comment_mime_type $comment_mime_type
        }
        
        # Scan for enabled actions
        if { [string equal $parent_trigger_type "workflow"] } {
            workflow::case::state_changed_handler \
                -case_id $case_id \
                -parent_enabled_action_id $parent_enabled_action_id \
                -user_id $user_id
        }

        # If there's a parent, alert the parent
        if { ![empty_string_p $parent_enabled_action_id] } {
            workflow::case::child_state_changed_handler \
                -parent_enabled_action_id $parent_enabled_action_id \
                -user_id $user_id
        }
    }
    
    workflow::case::flush_cache -case_id $case_id

    return $entry_id
}






#####
#
# Handling changes to state
#
####

ad_proc -private workflow::case::state_changed_handler {
    {-case_id:required}
    {-parent_enabled_action_id {}}
    {-user_id {}}
} {
    Scans for newly enabled actions, as well as actions which were 
    enabled but are now no longer enabled. Does not flush the cache. 
    Should only be called indirectly through the workflow API.

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_transaction {

        #----------------------------------------------------------------------
        # 1. Find the actually enabled actions, based on the current state(s) of the case
        #----------------------------------------------------------------------

        workflow::case::get_actual_state \
            -case_id $case_id \
            -parent_enabled_action_id $parent_enabled_action_id \
            -array assigned_p

        # assigned_p($action_id): 1 = assigned, 0 = enabled, nonexistent = not available ...

        #----------------------------------------------------------------------
        # 2. Output data structure
        #----------------------------------------------------------------------

        # Array with a key entry per action to enable
        array set enable_action_ids [array get assigned_p]
        
        # List of enabled_action_id's of actions that are no longer enabled
        set unenable_enabled_action_ids [list]

        #----------------------------------------------------------------------
        # 2. Get the rows in workflow_case_enabled_actions
        #----------------------------------------------------------------------
        if { [empty_string_p $parent_enabled_action_id] } {
            set db_rows [db_list_of_lists select_previously_enabled_actions_null_parent {}]
        } else {
            set db_rows [db_list_of_lists select_previously_enabled_actions {}]
        }

        foreach elm $db_rows {
            foreach { action_id enabled_action_id } $elm {}
            
            if { [info exists assigned_p($action_id)] } {
                # This action is enabled, and should be enabled => ignore
                unset enable_action_ids($action_id)
            } else {
                # This action is enabled, and shouldn't be, kill it
                lappend unenable_enabled_action_ids $enabled_action_id
            }
        }
        
        #----------------------------------------------------------------------
        # 3. Unenable the no-longer-enabled actions
        #----------------------------------------------------------------------
        foreach enabled_action_id $unenable_enabled_action_ids {
            workflow::case::action::unenable \
                -enabled_action_id $enabled_action_id
        }

        #----------------------------------------------------------------------
        # 4. Enabled the newly enabled actions
        #----------------------------------------------------------------------

        foreach action_id [array names enable_action_ids] {
            workflow::case::action::enable \
                -case_id $case_id \
                -action_id $action_id \
                -parent_enabled_action_id $parent_enabled_action_id \
                -user_id $user_id \
                -assigned=[exists_and_equal assigned_p($action_id) 1]
        }

        #----------------------------------------------------------------------
        # 6. Flush cache, assign roles
        #----------------------------------------------------------------------
        workflow::case::flush_cache -case_id $case_id
        workflow::case::assign_roles -all -case_id $case_id
    }
}

ad_proc -private workflow::case::child_state_changed_handler {
    -parent_enabled_action_id:required
    {-user_id {}}
} {
    Check if all child actions of this action are complete, and if so
    cause this action to execute
} {
    db_transaction {

        set num_incomplete [db_string select_num_incomplete {
            select count(*)
            from   workflow_case_enabled_actions
            where  parent_enabled_action_id = :parent_enabled_action_id
            and    completed_p = 'f'
        }]

        if { $num_incomplete > 0 } {
            # Still incomplete actions, do nothing
            return
        }

        #----------------------------------------------------------------------
        # All child actions are complete, execute the action
        #----------------------------------------------------------------------

        workflow::case::action::execute \
            -no_notification \
            -no_perm_check \
            -enabled_action_id $parent_enabled_action_id \
            -user_id $user_id
    }
}


#####
#
# Enable/Unenable/Complete individual actions
#
#####

ad_proc -private workflow::case::action::unenable {
    {-enabled_action_id:required}
} {
    Update the workflow_case_enabled_actions table to say that the 
    previously enabled actions are no longer enabled.
    Does not flush the cache. 
    Should only be called indirectly through the workflow API.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set action_id [workflow::case::enabled_action_get_element -enabled_action_id $enabled_action_id -element action_id]

    db_dml delete_enabled_action {
        delete 
        from   workflow_case_enabled_actions
        where  enabled_action_id = :enabled_action_id
    }
}

ad_proc -private workflow::case::action::enable {
    {-case_id:required}
    {-action_id:required}
    {-parent_enabled_action_id {}}
    {-user_id {}}
    {-assigned:boolean}
    {-assignees {}}
} {
    Update the workflow_case_enabled_actions table to say that the 
    action is now enabled. Will automatically fire an automatic action.
    Does not flush the cache. 
    Should only be called indirectly through the workflow API.

    @author Lars Pind (lars@collaboraid.biz)
} {
    workflow::action::get -action_id $action_id -array action
    set workflow_id $action(workflow_id)

    db_transaction {
        set enabled_action_id [db_nextval "workflow_case_enbl_act_seq"]

        if { ![string equal $action(trigger_type) "user"] } {
            # Action can only be assigned if it has trigger_type user
            # But its children can be assigned, so we keep the original assigned_p variable
            set db_assigned_p f
        } else {
            set db_assigned_p [db_boolean $assigned_p]
        }
        
        # Insert the enabled action row
        db_dml insert_enabled {}

        # Insert assignees
        if { [exists_and_not_null assignees] } {
            foreach party_id $assignees {
                db_dml insert_assignee {
                    insert into workflow_case_action_assignees (enabled_action_id, party_id)
                    values (:enabled_action_id, :party_id)
                }
            }
        }


        switch $action(trigger_type) {
            "workflow" {
                # Find and execute child init action
                set child_init_id [db_string child_init { 
                    select action_id
                    from   workflow_actions 
                    where  parent_action_id = :action_id
                    and    trigger_type = 'init'
                } -default {}]
                
                if { [empty_string_p $child_init_id] } {
                    error "Child workflow for action $action(pretty_name) doesn't have an action with trigger_type = 'init', or it has more than one."
                }
                
                workflow::action::fsm::get -action_id $child_init_id -array initial_action
                if { [empty_string_p $initial_action(new_state)] } {
                    error "Initial action with short_name \"$initial_action(short_name)\" does not have any new_state. In order to be an initial state, it must have new_state set."
                }

                workflow::case::action::execute \
                    -no_notification \
                    -initial \
                    -case_id $case_id \
                    -action_id $child_init_id \
                    -parent_enabled_action_id $enabled_action_id \
                    -user_id $user_id
            }
            "parallel" {
                # Find and enable child actions
                # TODO: Move this to action::get
                set child_actions [db_list child_actions { 
                    select action_id
                    from   workflow_actions
                    where  parent_action_id = :action_id
                }]
                foreach child_action_id $child_actions {
                    workflow::case::action::enable \
                        -case_id $case_id \
                        -action_id $child_action_id \
                        -parent_enabled_action_id $enabled_action_id \
                        -user_id $user_id \
                        -assigned=$assigned_p
                }
            }
            "dynamic" {
                # HACK: just pick each user from the assigned role ...
                # TODO: Move this to action::get
                set child_actions [db_list child_actions { 
                    select action_id
                    from   workflow_actions
                    where  parent_action_id = :action_id
                }]
                
                foreach child_action_id $child_actions {

                    set child_role_id [workflow::action::get_element \
                                        -action_id $child_action_id \
                                        -element assigned_role_id]

                    set parties [workflow::case::role::get_assignees \
                                     -case_id $case_id \
                                     -role_id $child_role_id]


                    foreach elm $parties {
                        array unset party 
                        array set party $elm

                        workflow::case::action::enable \
                            -case_id $case_id \
                            -action_id $child_action_id \
                            -parent_enabled_action_id $enabled_action_id \
                            -user_id $user_id \
                            -assigned=$assigned_p \
                            -assignees $party(party_id)
                    }
                }
            }
            "auto" {
                workflow::case::action::execute \
                    -no_perm_check \
                    -enabled_action_id $enabled_action_id \
                    -user_id $user_id
            }
        }
    }
}

ad_proc -private workflow::case::action::complete {
    {-enabled_action_id:required}
    {-user_id {}}
} {
    Mark an action complete.

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_transaction {
        workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
        workflow::action::get -action_id $enabled_action(action_id) -array action
        
        if { [lsearch -exact { parallel dynamic } $enabled_action(parent_trigger_type)] != -1 } {
            db_dml completed_p {
                update workflow_case_enabled_actions
                set    completed_p = 't'
                where  enabled_action_id = :enabled_action_id
            }

            # Delete children
            db_dml delete_enabled_actions {
                delete
                from   workflow_case_enabled_actions
                where  parent_enabled_action_id = :enabled_action_id
            }
        } else {
            # Delete the workflow_case_enabled_actions row
            # Will cascade delete the corresponding state information
            set case_id $enabled_action(case_id)
            db_dml delete_enabled_actions {
                delete
                from   workflow_case_enabled_actions
                where  enabled_action_id = :enabled_action_id
            }
        }
    }
}






#####
#
# Helper
#
#####

ad_proc -private workflow::case::get_actual_state {
    {-case_id:required}
    {-parent_enabled_action_id {}}
    {-array:required}
} {
    Flushes cache, gets actual state of case, and finds which actions
    should be enabled/assigned based on that actual state. This can
    then be used to manage the contents of
    workflow_case_enabled_actions table.
} {
    # TODO B: Make polymorphic -- this should go into a ::fsm:: namespace
    upvar 1 $array assigned_p
    
    workflow::case::flush_cache -case_id $case_id
    
    set state_id [workflow::case::fsm::get_state_info \
                      -case_id $case_id \
                      -parent_enabled_action_id $parent_enabled_action_id] 
    
    workflow::state::fsm::get -state_id $state_id -array state
    
    foreach action_id $state(enabled_action_ids) {
        set assigned_p($action_id) 0
    }
    
    foreach action_id $state(assigned_action_ids) {
        set assigned_p($action_id) 1
    }
}

ad_proc -private workflow::case::action::fsm::execute_state_change {
    {-initial:boolean}
    {-case_id {}}
    {-action_id {}}
    {-enabled_action_id {}}
    {-parent_enabled_action_id {}}
} {
    Modify the state of the case as required when executing the given action.

    @param case_id            The ID of the case.

    @param action_id          The ID of the action

    @param enabled_action_id  The ID of the action

    @param initial            Set this if this is an initial action.

    @param parent_enabled_action_id
                              Specify this, if this is an initial action.

    @author Lars Pind (lars@collaboraid.biz)
} {

    db_transaction {

        if { [empty_string_p $case_id] || [empty_string_p $action_id] } {
            if { [empty_string_p $enabled_action_id] } {
                error "You must supply either case_id and action_id, or enabled_action_id"
            }
        } 

        if { [empty_string_p $enabled_action_id] } {
            if { $initial_p } {
                set enabled_action_p {}
                # We rely on parent_enabled_action_id being set by the caller here
            } else {
                # This will not work with dynamic actions, but is necessary for inital actions
                set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                           -case_id $case_id \
                                           -action_id $action_id \
                                           -parent_enabled_action_id $parent_enabled_action_id]
            }
        }

        if { ![empty_string_p $enabled_action_id] } {
            workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
            # Even if these are provided, we overide them with the DB call
            set case_id $enabled_action(case_id)
            set action_id $enabled_action(action_id)
            set parent_enabled_action_id $enabled_action(parent_enabled_action_id)
        }

        # Find the new state from the action
        workflow::action::get -action_id $action_id -array action
        set new_state_id $action(new_state_id)

        # Actually change the state, if any state change
        if { ![empty_string_p $new_state_id] } {
            # Delete any existing state with this parent_enabled_action_id

            if { [empty_string_p $parent_enabled_action_id] } {
                db_dml delete_fsm_state {
                    delete 
                    from   workflow_case_fsm
                    where  case_id = :case_id
                    and    parent_enabled_action_id is null
                }
            } else {
                db_dml delete_fsm_state {
                    delete 
                    from   workflow_case_fsm
                    where  case_id = :case_id
                    and    parent_enabled_action_id = :parent_enabled_action_id
                }
            }

            # Insert the new one
            db_dml insert_fsm_state {
                insert into workflow_case_fsm (case_id, parent_enabled_action_id, current_state)
                values (:case_id, :parent_enabled_action_id, :new_state_id)
            }
        }
    }
}
