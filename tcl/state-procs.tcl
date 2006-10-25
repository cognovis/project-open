ad_library {
    Procedures in the workflow::fsm::state namespace and
    in its child namespaces.
    
    @creation-date 8 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::state::fsm {}

#####
#
#  workflow::state::fsm namespace
#
#####

ad_proc -public workflow::state::fsm::new {
    {-workflow_id:required}
    {-internal:boolean}
    {-short_name {}}
    {-pretty_name:required}
    {-hide_fields {}}
    {-sort_order {}}
    {-parent_action {}}
} {
    Creates a new state for a certain FSM (Finite State Machine) workflow.
    
    @param workflow_id The id of the FSM workflow to add the state to

    @param short_name   If you leave blank, the short_name will be generated from pretty_name.

    @param pretty_name  

    @param hide_fields  A space-separated list of the names of form fields which should be
                        hidden when in this state, because they're irrelevant in a certain state.

    @param sort_order   The number which this state should be in the sort ordering sequence. 
                        Leave blank to add state at the end. If you provide a sort_order number
                        which already exists, existing states are pushed down one number.
    
    @param parent_action
                        Which action with trigger_type 'workflow' does this state belong to.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @return ID of new state.
    
    @author Peter Marklund
} {        
    # Wrapper for workflow::state::fsm::edit

    foreach elm { short_name pretty_name sort_order parent_action } {
        set row($elm) [set $elm]
    }

    set state_id [workflow::state::fsm::edit \
                      -operation "insert" \
                      -workflow_id $workflow_id \
                      -array row]

    return $state_id
}

ad_proc -public workflow::state::fsm::edit {
    {-operation "update"}
    {-state_id {}}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
    {-no_complain:boolean}
    {-handlers {}}
} {
    Edit a workflow state. 

    Attributes of the array are: 

    <ul>
      <li>short_name
      <li>pretty_name
      <li>sort_order
      <li>hide_fields
      <li>parent_action

    </ul>

    @param operation    insert, update, delete

    @param state_id     For update/delete: The state to update or delete. 
                        For insert: Optionally specify a pre-generated state_id for the state.

    @param workflow_id  For update/delete: Optionally specify the workflow_id. If not specified, we will execute a query to find it.
                        For insert: The workflow_id of the new state.
    
    @param array        For insert/update: Name of an array in the caller's namespace with attributes to insert/update.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @param no_complain  Silently ignore extra attributes that we don't know how to handle. 
                        
    @return             state_id
    
    @see workflow::state::new

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {        
    switch $operation {
        update - delete {
            if { [empty_string_p $state_id] } {
                error "You must specify the state_id of the state to $operation."
            }
        }
        insert {}
        default {
            error "Illegal operation '$operation'"
        }
    }
    switch $operation {
        insert - update {
            upvar 1 $array row
            if { ![array exists row] } {
                error "Array $array does not exist or is not an array"
            }
            foreach name [array names row] {
                set missing_elm($name) 1
            }
        }
    }
    switch $operation {
        insert {
            if { [empty_string_p $workflow_id] } {
                error "You must supply workflow_id"
            }
            # Default sort_order
            if { ![exists_and_not_null row(sort_order)] } {
                set row(sort_order) [workflow::default_sort_order \
                                         -workflow_id $workflow_id \
                                         -table_name "workflow_fsm_states"]
            }
            # Default short_name on insert
            if { ![info exists row(short_name)] } {
                set row(short_name) {}
            }
        }
        update {
            if { [empty_string_p $workflow_id] } {
                set workflow_id [workflow::state::fsm::get_element \
                                     -state_id $state_id \
                                     -element workflow_id]
            }
        }
    }

    # Parse column values
    switch $operation {
        insert - update {
            # Special-case: array entry parent_action (takes short_name) and parent_action_id (takes action_id) -- 
            # DB column is parent_action_id (takes action_id_id)
            if { [info exists row(parent_action)] } {
                if { [info exists row(parent_action_id)] } {
                    error "You cannot supply both parent_action (takes short_name) and parent_action_id (takes action_id)"
                }
                if { ![empty_string_p $row(parent_action)] } {
                    set row(parent_action_id) [workflow::action::get_id \
                                                    -workflow_id $workflow_id \
                                                    -short_name $row(parent_action)]
                } else {
                    set row(parent_action_id) [db_null]
                }
                unset row(parent_action)
                unset missing_elm(parent_action)
            }

            set update_clauses [list]
            set insert_names [list]
            set insert_values [list]

            # Handle columns in the workflow_fsm_states table
            foreach attr { 
                short_name pretty_name hide_fields sort_order parent_action_id
            } {
                if { [info exists row($attr)] } {
                    set varname attr_$attr
                    # Convert the Tcl value to something we can use in the query
                    switch $attr {
                        short_name {
                            if { ![exists_and_not_null row(pretty_name)] } {
                                if { [empty_string_p $row(short_name)] } {
                                    error "You cannot edit with an empty short_name without also setting pretty_name"
                                } else {
                                    set row(pretty_name) {}
                                }
                            }
                            
                            set $varname [workflow::state::fsm::generate_short_name \
                                              -workflow_id $workflow_id \
                                              -pretty_name $row(pretty_name) \
                                              -short_name $row(short_name) \
                                              -state_id $state_id]
                        }
                        default {
                            set $varname $row($attr)
                        }
                    }
                    # Add the column to the insert/update statement
                    switch $attr {
                        default {
                            lappend update_clauses "$attr = :$varname"
                            lappend insert_names $attr
                            lappend insert_values :$varname
                        }
                    }
                    if { [info exists missing_elm($attr)] } {
                        unset missing_elm($attr)
                    }
                }
            }

            # Auxilliary helper attributes (enabled_actions -> enabled_action_ids, assigned_actions -> assigned_action_ids)

            # Enabled actions
            if { [info exists row(enabled_actions)] } {
                if { [info exists row(enabled_action_ids)] } {
                    error "You cannot supply both enabled_actions and enabled_actions_ids"
                }
                set row(enabled_action_ids) [list]
                foreach action_short_name $row(enabled_actions) {
                    lappend row(enabled_action_ids) [workflow::action::get_id \
                                                         -workflow_id $workflow_id \
                                                         -short_name $action_short_name]
                }
                unset row(enabled_actions)
            }
            
            # Assigend actions
            if { [info exists row(assigned_actions)] } {
                if { [info exists row(assigned_action_ids)] } {
                    error "You cannot supply both assigned_actions and assigned_action_ids"
                }
                set row(assigned_action_ids) [list]
                foreach action_short_name $row(assigned_actions) {
                    lappend row(assigned_action_ids) [workflow::action::get_id \
                                                        -workflow_id $workflow_id \
                                                        -short_name $action_short_name]
                }
                unset row(assigned_actions)
            }

            # Handle auxillary rows
            array set aux [list]
            foreach attr { 
                enabled_action_ids assigned_action_ids
            } {
                if { [info exists row($attr)] } {
                    set aux($attr) $row($attr)
                    unset row($attr)
                }
            }
        }
    }
    
    db_transaction {
        # Sort_order
        switch $operation {
            insert - update {
                if { [info exists row(sort_order)] } {
                    workflow::state::fsm::update_sort_order \
                        -workflow_id $workflow_id \
                        -sort_order $row(sort_order)
                }
            }
        }
        # Do the insert/update/delete
        switch $operation {
            insert {
                if { [empty_string_p $state_id] } {
                    set state_id [db_nextval "workflow_fsm_states_seq"]
                }

                lappend insert_names state_id
                lappend insert_values :state_id
                lappend insert_names workflow_id
                lappend insert_values :workflow_id

                db_dml insert_state "
                    insert into workflow_fsm_states
                    ([join $insert_names ", "])
                    values
                    ([join $insert_values ", "])
                "
            }
            update {
                if { [llength $update_clauses] > 0 } {
                    db_dml update_state "
                        update workflow_fsm_states
                        set    [join $update_clauses ", "]
                        where  state_id = :state_id
                    "
                }
            }
            delete {
                db_dml delete_state {
                    delete from workflow_fsm_states
                    where state_id = :state_id
                }
            }
        }

        # Auxilliary rows
        switch $operation {
            insert - update {

                # Record in which actions the action is enabled but not assigned
                if { [info exists aux(enabled_action_ids)] } {
                    set assigned_p "f"
                    db_dml delete_enabled_actions {}
                    foreach enabled_action_id $aux(enabled_action_ids) {
                        db_dml insert_enabled_action {}
                    }
                    unset aux(enabled_action_ids)
                }
                
                # Record where the action is both enabled and assigned
                if { [info exists aux(assigned_action_ids)] } {
                    set assigned_p "t"
                    db_dml delete_enabled_actions {}
                    foreach enabled_action_id $aux(assigned_action_ids) {
                        db_dml insert_enabled_action {}
                    }
                    unset aux(assigned_action_ids)
                }

                # Check that there are no unknown attributes
                if { [llength [array names missing_elm]] > 0 && !$no_complain_p } {
                    error "Trying to set illegal state attributes: [join [array names missing_elm] ", "]"
                }
            }
        }

        if { !$internal_p } {
            workflow::definition_changed_handler -workflow_id $workflow_id
        }
    }

    return $state_id
}

ad_proc -private workflow::state::fsm::update_sort_order {
    {-workflow_id:required}
    {-sort_order:required}
} {
    Increase the sort_order of other states, if the new sort_order is already taken.
} { 
    set sort_order_taken_p [db_string select_sort_order_p {}]
    if { $sort_order_taken_p } {
        db_dml update_sort_order {}
    }
}

ad_proc -public workflow::state::fsm::get_existing_short_names {
    {-workflow_id:required}
    {-ignore_state_id {}}
} {
    Returns a list of existing state short_names in this workflow.
    Useful when you're trying to ensure a short_name is unique, 
    or construct a new short_name that is guaranteed to be unique.

    @param ignore_state_id   If specified, the short_name for the given state will not be included in the result set.
} {
    set result [list]

    foreach state_id [workflow::fsm::get_states -all -workflow_id $workflow_id] {
        if { [empty_string_p $ignore_state_id] || ![string equal $ignore_state_id $state_id] } {
            lappend result [workflow::state::fsm::get_element -state_id $state_id -element short_name]
        }
    }

    return $result
}

ad_proc -public workflow::state::fsm::generate_short_name {
    {-workflow_id:required}
    {-pretty_name:required}
    {-short_name {}}
    {-state_id {}}
} {
    Generate a unique short_name from pretty_name.
    
    @param state_id    If you pass in this, we will allow that state's short_name to be reused.
    
} {
    set existing_short_names [workflow::state::fsm::get_existing_short_names \
                                  -workflow_id $workflow_id \
                                  -ignore_state_id $state_id]
    
    if { [empty_string_p $short_name] } {
        if { [empty_string_p $pretty_name] } {
            error "Cannot have empty pretty_name when short_name is empty"
        }
        set short_name [util_text_to_url \
                            -replacement "_" \
                            -existing_urls $existing_short_names \
                            -text $pretty_name]
    } else {
        # Make lowercase, remove illegal characters
        set short_name [string tolower $short_name]
        regsub -all {[- ]} $short_name {_} short_name
        regsub -all {[^a-zA-Z_0-9]} $short_name {} short_name

        if { [lsearch -exact $existing_short_names $short_name] != -1 } {
            error "State with short_name '$short_name' already exists in this workflow."
        }
    }

    return $short_name
}


ad_proc -public workflow::state::fsm::get {
    {-state_id:required}
    {-array:required}
} {
    Return workflow_id, sort_order, short_name, and pretty_name for a certain
    FSM workflow state.

    @author Peter Marklund
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    set workflow_id [workflow::state::fsm::get_workflow_id -state_id $state_id]
    array set state_data [workflow::state::fsm::get_all_info -workflow_id $workflow_id]

    array set row $state_data($state_id)
}

ad_proc -public workflow::state::fsm::get_element {
    {-state_id {}}
    {-one_id {}}
    {-element:required}
} {
    Return a single element from the information about a state.

    @param state_id The ID of the workflow
    @param one_id    Same as state_id, just used for consistency across roles/actions/states.

    @return The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $state_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either state_id or one_id"
        }
        set state_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either state_id or one_id"
        }
    }

    get -state_id $state_id -array row
    return $row($element)
}

ad_proc -public workflow::state::fsm::get_id {
    {-workflow_id:required}
    {-short_name:required}
} {
    Return the id of the state with given short name

    @param workflow_id The id of the workflow the state belongs to.
    @param short_name The name of the state to return the id for.

    @author Peter Marklund
} {
    return [db_string select_id {}]
}

ad_proc -public workflow::state::fsm::get_workflow_id {
    {-state_id:required}
} {
    Lookup the workflow that the given state belongs to.

    @return The id of the workflow the state belongs to.

    @author Peter Marklund
} {
    return [util_memoize \
            [list workflow::state::fsm::get_workflow_id_not_cached -state_id $state_id]]
}

ad_proc -public workflow::state::fsm::pretty_name_unique_p {
    -workflow_id:required
    -pretty_name:required
    {-parent_action_id {}}
    {-state_id {}}
} {
    Check if suggested pretty_name is unique. 
    
    @return 1 if unique, 0 if not unique.
} {
    set exists_p [db_string name_exists { 
        select count(*) 
        from   workflow_fsm_states
        where  workflow_id = :workflow_id
        and    pretty_name = :pretty_name
        and    (:parent_action_id is null or parent_action_id = :parent_action_id)
        and    (:state_id is null or state_id != :state_id)
    }]
    return [expr !$exists_p]
}



#####
# Private procs
#####

ad_proc -private workflow::state::fsm::get_ids {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the state_id's of all the states in the workflow. 
    
    @param workflow_id The ID of the workflow
    @return list of state_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Use cached data
    array set state_data [workflow::state::fsm::get_all_info -workflow_id $workflow_id]
    if { $all_p } {
        return $state_data(state_ids)
    }
    set state_ids [list]
    foreach state_id $state_data(state_ids) {
        if { [workflow::state::fsm::get_element \
                  -state_id $state_id \
                  -element parent_action_id] == $parent_action_id } {
            lappend state_ids $state_id
        }
    }
    return $state_ids
}

ad_proc -private workflow::state::fsm::get_workflow_id_not_cached {
    {-state_id:required}
} {
    This proc is used internally by the workflow API only. Use the proc
    workflow::state::fsm::get_workflow_id instead.

    @author Peter Marklund
} {
    return [db_string select_workflow_id {}]
}

ad_proc -private workflow::state::fsm::parse_spec {
    {-workflow_id:required}
    {-short_name:required}
    {-spec:required}
    {-parent_action_id {}}
} {
    Parse the spec for an individual state definition.

    @param workflow_id The id of the workflow to delete.
    @param short_name The short_name of the state
    @param spec The state spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Initialize array with default values
    array set state { 
        hide_fields {} 
    }
    
    # Get the info from the spec
    foreach { key value } $spec {
        set state($key) [string trim $value]
    }
    set state(short_name) $short_name
    set state(parent_action_id) $parent_action_id

    # Create the state
    set state_id [workflow::state::fsm::edit \
                      -operation "insert" \
                      -workflow_id $workflow_id \
                      -array state]

}

ad_proc -private workflow::state::fsm::generate_spec {
    {-state_id {}}
    {-one_id {}}
    {-handlers {}}
} {
    Generate the spec for an individual state definition.

    @param state_id The id of the state to generate spec for.

    @param one_id    Same as state_id, just used for consistency across roles/actions/states.

    @return spec The states spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $state_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either state_id or one_id"
        }
        set state_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either state_id or one_id"
        }
    }

    get -state_id $state_id -array row

    # Get rid of elements that shouldn't go into the spec
    array unset row short_name 
    array unset row state_id
    array unset row workflow_id
    array unset row sort_order
    array unset row parent_action
    array unset row parent_action_id
    array unset row enabled_actions
    array unset row enabled_action_ids
    array unset row assigned_actions
    array unset row assigned_action_ids
    
    set spec {}
    foreach name [lsort [array names row]] {
        if { ![empty_string_p $row($name)] } {
            lappend spec $name $row($name)
        }
    }

    return $spec
}
    
ad_proc -private workflow::state::fsm::generate_states_spec {
    {-workflow_id:required}
} {
    Generate the spec for the block containing the definition of all
    states for the workflow.

    @param workflow_id The id of the workflow to get the states spec for

    @return The states spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    # states(short_name) { ... state-spec ... }
    set states_list [list]
    foreach state_id [workflow::fsm::get_states -workflow_id $workflow_id] {
        lappend states_list [get_element -state_id $state_id -element short_name] [generate_spec -state_id $state_id]
    }
    
    return $states_list

}

ad_proc -private workflow::state::flush_cache {
    {-workflow_id:required}
} {
    Flush all caches related to state information for
    the given workflow. Used internally by the workflow API
    only.

    @author Peter Marklund
} {
    # TODO: Flush request cache
    # ...

    # Flush the thread global cache
    util_memoize_flush [list workflow::state::fsm::get_all_info_not_cached -workflow_id $workflow_id]    
}

ad_proc -private workflow::state::fsm::get_all_info {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only.
    Returns all information related to states for a certain
    workflow instance. Uses util_memoize to cache values.

    @see workflow::state::fsm::get_all_info_not_cached

    @author Peter Marklund
} {
    return [util_memoize [list workflow::state::fsm::get_all_info_not_cached \
            -workflow_id $workflow_id] [workflow::cache_timeout]]
}

ad_proc -private workflow::state::fsm::get_all_info_not_cached {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only and
    should not be invoked directly from application code. Returns
    all information related to states for a certain workflow instance.
    Goes to the database on every invocation and should be used together
    with util_memoize.

    @author Peter Marklund
} {
    # state_data will be an array keyed by state_id
    # state_data(123) = array-list with: hide_fields, pretty_name, short_name, state_id, sort_order, workflow_id,
    #                                    enabled_actions, enabled_action_ids, assigned_actions, assigned_action_ids
    # In addition:
    # state_data(state_ids) = [list of state_ids in sort order]
    array set state_data [list]

    # state_array_$state_id is an internal datastructure. It's the array for each state_id entry
    # but as a separate array making it easier to lappend to individual entries

    #----------------------------------------------------------------------
    # Get core state information from DB
    #----------------------------------------------------------------------

    # Use a list to be able to retrieve states in sort order
    set state_ids [list]
    db_foreach select_states {} -column_array state_row {
        # Cache the state_id -> workflow_id lookup
        util_memoize_seed \
                [list workflow::state::fsm::get_workflow_id_not_cached -state_id $state_row(state_id)] \
                $workflow_id

        set state_id $state_row(state_id)

        array set state_array_$state_id [array get state_row]
        
        lappend state_ids $state_id
    }
    set state_data(state_ids) $state_ids

    array set action_short_name [list]

    #----------------------------------------------------------------------
    # Build state-action map
    #----------------------------------------------------------------------

    # Will be stored like this:
    # assigned_p_${state_id}($action_id) = 1 if assigned, 0 if enabled, non-existent if neither

    # In addition, we have a supporting structure of action information
    #   action_info(${action_id},short_name)
    #   action_info(${action_id},trigger_type)
    #   action_info(${action_id},always_enabled_p)
    #   action_info(${action_id},parent_action_id)
    #   action_info(${action_id},child_action_ids)

    # 1. Get action data: trigger_type, always_enabled, hierarchy
    db_foreach always_enabled_actions {
        select action_id, 
               short_name, 
               trigger_type, 
               always_enabled_p, 
               parent_action_id
        from   workflow_actions
        where  workflow_id = :workflow_id
    } {
        set action_info(${action_id},short_name) $short_name
        set action_info(${action_id},trigger_type) [string trim $trigger_type]
        set action_info(${action_id},parent_action_id) $parent_action_id
        if { [template::util::is_true $always_enabled_p] && [lsearch { user auto message } $trigger_type] != -1 } {
            set action_info(${action_id},always_enabled_p) 1
        } else {
            set action_info(${action_id},always_enabled_p) 0
        }

        # Store as a child of parent NOTE: Not needed any longer
        if { ![empty_string_p $parent_action_id] } {
            lappend action_info(${parent_action_id},child_action_ids) $action_id
        }

        # Mark enabled in all states that have the same parent as the action
        if { $action_info(${action_id},always_enabled_p) } {
            foreach state_id $state_ids {
                if { [string equal $parent_action_id [set state_array_${state_id}(parent_action_id)]] } {
                    set assigned_p_${state_id}($action_id) 0
                }
            }
        }
    }
    
    # 2. Get action-state map
    db_foreach always_enabled_actions {
        select e.action_id, 
               e.state_id,  
               e.assigned_p
        from   workflow_actions a,
               workflow_fsm_action_en_in_st e
        where  a.workflow_id = :workflow_id
        and    a.action_id = e.action_id
    } {
        set assigned_p_${state_id}($action_id) [template::util::is_true $assigned_p]
    }
    
    # 3. Put stuff back into the output array
    foreach state_id $state_ids {
        set state_array_${state_id}(enabled_action_ids) [list]
        set state_array_${state_id}(enabled_actions) [list]
        set state_array_${state_id}(assigned_action_ids) [list]
        set state_array_${state_id}(assigned_actions) [list]
        
        if { [info exists assigned_p_${state_id}] } {
            foreach action_id [array names assigned_p_${state_id}] {
                # Enabled
                lappend state_array_${state_id}(enabled_action_ids) $action_id
                lappend state_array_${state_id}(enabled_actions) $action_info(${action_id},short_name)
                
                # Assigned
                if { [set assigned_p_${state_id}($action_id)] } {
                    lappend state_array_${state_id}(assigned_action_ids) $action_id
                    lappend state_array_${state_id}(assigned_actions) $action_info(${action_id},short_name)
                }
            }
        }
    }

    #----------------------------------------------------------------------
    # Final output
    #----------------------------------------------------------------------

    # Move over to normal array
    foreach state_id $state_ids {
        set state_data($state_id) [array get state_array_$state_id]
    }

    return [array get state_data]}

