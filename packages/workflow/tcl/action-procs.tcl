ad_library {
    Procedures in the workflow::action namespace.
    
    @creation-date 9 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::action {}
namespace eval workflow:::action::fsm {}




#####
#
#  workflow::action namespace
#
#####

ad_proc -public workflow::action::new {
    {-workflow_id:required}
    {-action_id {}}
    {-sort_order {}}
    {-short_name {}}
    {-pretty_name:required}
    {-pretty_past_tense {}}
    {-edit_fields {}}
    {-assigned_role {}}
    {-allowed_roles {}}
    {-privileges {}}
    {-callbacks {}}
    {-always_enabled_p f}
    -initial_action_p
    {-trigger_type user}
    {-parent_action {}}
    {-description {}}
    {-description_mime_type {}}
    {-timeout_seconds {}}
    {-internal:boolean}
} {
    This procedure is normally not invoked from application code. Instead
    a procedure for a certain workflow implementation, such as for example
    workflow::action::fsm::new (for Finite State Machine workflows), is used.

    @param workflow_id            The id of the FSM workflow to add the action to

    @param action_id              Optionally specify the ID of the new action.

    @param sort_order             The number which this action should be in the sort ordering sequence. 
                                  Leave blank to add action at the end. If you provide a sort_order number
                                  which already exists, existing actions are pushed down one number.

    @param short_name             Short name of the action for use in source code.
                                  Should be on Tcl variable syntax.

    @param pretty_name            Human readable name of the action for use in UI.

    @param pretty_past_tense      Past tense of pretty name

    @param edit_fields            A space-separated list of the names of form fields which should be
                                  opened for editing when this action is carried out.

    @param assigned_role          The short_name of an assigned role. Users in this 
                                  role are expected (obliged) to take 
                                  the action.

    @param allowed_roles          A list of role short_names or IDs. Users in these roles are 
                                  allowed to take the action.
                                  
    @param privileges             Users with these privileges on the object 
                                  treated by the workflow (i.e. a bug in the 
                                  Bug Tracker) will be allowed to take this 
                                  action.

    @param callbacks              List of names of service contract implementations of callbacks for the action in 
                                  impl_owner_name.impl_name format.

    @param trigger_type           user, auto, message, time, init, workflow, parallel, dynamic.

    @param parent_action          Short_name of the action's parent action.

    @param initial_action_p       Deprecated. Use this switch to indicate that this is the initial
                                  action that will fire whenever a case of the workflow
                                  is created. The initial action is used to determine
                                  the initial state of the worklow as well as any 
                                  procedures that should be executed when the case created.

    @param timeout_seconds        If zero, the action will automatically fire whenever it becomes enabled.
                                  If greater than zero, the action will automatically fire x number of
                                  seconds after the action is enabled. If empty, will never fire automatically.

    @param internal               Set this flag if you're calling this proc from within the corresponding proc 
                                  for a particular workflow model. Will cause this proc to not flush the cache 
                                  or call workflow::definition_changed_handler, which the caller must then do.

    @return The id of the created action

    @see workflow::action::edit
    @see workflow::action::fsm::edit
    @see workflow::definition_changed_handler

    @author Peter Marklund
} {
    # Wrapper for workflow::action::edit
    
    array set row [list]
    foreach col { 
        initial_action_p sort_order short_name pretty_name
        pretty_past_tense edit_fields allowed_roles assigned_role 
        privileges callbacks always_enabled_p description description_mime_type 
        timeout_seconds trigger_type parent_action
    } {
        if { [info exists $col] } {
            set row($col) [set $col]
        }
    }

    set action_id [workflow::action::edit \
                       -operation "insert" \
                       -action_id $action_id \
                       -workflow_id $workflow_id \
                       -array row]

    return $action_id
}

ad_proc -public workflow::action::edit {
    {-operation "update"}
    {-action_id {}}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
    {-no_complain:boolean}
    {-handlers { 
        roles "workflow::role" 
        actions "workflow::action"
    }}
} {
    Edit an action. 

    Attributes of the array: 

    <ul>
      <li>short_name
      <li>pretty_name
      <li>pretty_past_tense
      <li>edit_fields
      <li>description 
      <li>description_mime_type
      <li>sort_order
      <li>always_enabled_p 
      <li>assigned_role
      <li>timeout_seconds
      <li>trigger_type
      <li>parent_action
      <li>parent_action_id
      <li>privileges
      <li>allowed_roles
      <li>callbacks
      <li>child_actions
    </ul>

    Deprecated but still supported:

    <ul>
      <li>initial_action_p
    </ul>
    
    @param operation    insert, update, delete

    @param action_id    For update/delete: The action to update or delete. 
                        For insert: Optionally specify a pre-generated action_id for the action.

    @param workflow_id  For update/delete: Optionally specify the workflow_id. If not specified, we will execute a query to find it.
                        For insert: The workflow_id of the new action.
    
    @param array        For insert/update: Name of an array in the caller's namespace with attributes to insert/update.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @param no_complain  Silently ignore extra attributes that we don't know how to handle. 
                        
    @return action_id
    
    @author Lars Pind (lars@collaboraid.biz)

    @see workflow::action::new
} {
    switch $operation {
        update - delete {
            if { [empty_string_p $action_id] } {
                error "You must specify the action_id of the action to $operation."
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
                                         -table_name "workflow_actions"]
            }
            # Default short_name on insert
            if { ![info exists row(short_name)] } {
                set row(short_name) {}
            }
        }
        update - delete {
            if { [empty_string_p $workflow_id] } {
                set workflow_id [workflow::action::get_element \
                                     -action_id $action_id \
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
                    error "You cannot supply both parent_action ($row(parent_action)) (takes short_name) and parent_action_id ($row(parent_action_id)) (takes action_id)"
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

            # Record if this is an initial action (deprecated)
            if { [info exists row(initial_action_p)] } {
                if { [info exists row(trigger_type)] && ![string equal $row(trigger_type) "user"] } {
                    error "You can't specify both initial_action_p (which is deprecated) and trigger_type (which has replaced it) at the same time. Stick to trigger_type."
                }
                if { [template::util::is_true $row(initial_action_p)] } {
                    set row(trigger_type) "init"
                }
                unset row(initial_action_p)
                unset missing_elm(initial_action_p)
            }

            set update_clauses [list]
            set insert_names [list]
            set insert_values [list]
            # Handle columns in the workflow_actions table
            foreach attr { 
                short_name 
                pretty_name
                pretty_past_tense
                edit_fields
                description 
                description_mime_type
                sort_order
                always_enabled_p
                assigned_role
                timeout_seconds
                trigger_type
                parent_action_id
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
                                
                            set $varname [workflow::action::generate_short_name \
                                              -workflow_id $workflow_id \
                                              -pretty_name $row(pretty_name) \
                                              -short_name $row(short_name) \
                                              -action_id $action_id]
                        }
                        always_enabled_p {
                            set $varname [db_boolean [template::util::is_true $row($attr)]]
                        }
                        assigned_role {
                            if { [empty_string_p $row($attr)] } {
                                set $varname [db_null]
                            } else {
                                # Get role_id by short_name
                                set $varname [workflow::role::get_id \
                                                  -workflow_id $workflow_id \
                                                  -short_name $row($attr)]
                            }
                        }
                        default {
                            set $varname $row($attr)
                        }
                    }
                    # Add the column to the insert/update statement
                    switch $attr {
                        timeout_seconds {
                            lappend update_clauses "[db_map update_timeout_seconds_name] = [db_map update_timeout_seconds_value]"
                            lappend insert_names [db_map update_timeout_seconds_name]
                            lappend insert_values [db_map update_timeout_seconds_value]
                        }
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
        }
    }
    
    db_transaction {
        # Sort_order
        switch $operation {
            insert - update {
                if { [info exists row(sort_order)] } {
                    workflow::action::update_sort_order \
                        -workflow_id $workflow_id \
                        -sort_order $row(sort_order)
                }
            }
        }
        # Do the insert/update/delete
        switch $operation {
            insert {
                if { [empty_string_p $action_id] } {
                    set action_id [db_nextval "workflow_actions_seq"]
                }

                lappend insert_names action_id
                lappend insert_values :action_id
                lappend insert_names workflow_id
                lappend insert_values :workflow_id

                db_dml insert_action "
                    insert into workflow_actions
                    ([join $insert_names ", "])
                    values
                    ([join $insert_values ", "])
                "
            }
            update {
                if { [llength $update_clauses] > 0 } {
                    db_dml update_action "
                        update workflow_actions
                        set    [join $update_clauses ", "]
                        where  action_id = :action_id
                    "
                }
            }
            delete {
                db_dml delete_action {
                    delete from workflow_actions
                    where action_id = :action_id
                }
            }
        }
        
        # Auxilliary rows
        switch $operation {
            insert - update {
                # Record which roles are allowed to take action
                if { [info exists row(allowed_roles)] } {
                    db_dml delete_allowed_roles {
                        delete from workflow_action_allowed_roles
                        where  action_id = :action_id
                    }
                    foreach allowed_role $row(allowed_roles) {
                        db_dml insert_allowed_role {}
                    }
                    unset missing_elm(allowed_roles)
                }
                
                # Record which privileges enable the action
                if { [info exists row(privileges)] } {
                    db_dml delete_privileges {
                        delete from workflow_action_privileges
                        where  action_id = :action_id
                    }
                    foreach privilege $row(privileges) {
                        db_dml insert_privilege {}
                    }
                    unset missing_elm(privileges)
                }
                     
                # Callbacks
                if { [info exists row(callbacks)] } {
                    db_dml delete_callbacks {
                        delete from workflow_action_callbacks
                        where  action_id = :action_id
                    }
                    foreach callback_name $row(callbacks) {
                        workflow::action::callback_insert \
                            -action_id $action_id \
                            -name $callback_name
                    }
                    unset missing_elm(callbacks)
                }

                # Child actions
                foreach { type namespace } $handlers {
                    # type is 'roles', 'actions', 'states', etc.
                    if { [info exists row(child_${type})] } {

                        # First, delete existing objects
                        foreach existing_action_id [${namespace}::get_ids \
                                                        -workflow_id $workflow_id \
                                                        -parent_action_id $action_id]  {
                            # LARS: Ugly as hell with the string range to cut from 'actions' to 'action_id'
                            ${namespace}::edit -[string range $type 0 end-1]_id $existing_action_id
                        }

                        foreach { child_short_name child_spec } $row(child_${type}) {
                            array unset child
                            array set child $child_spec
                            set child(short_name) $child_short_name 
                            set child(parent_action_id) $action_id

                            # string trim everything
                            foreach key [array names child] { 
                                set child($key) [string trim $child($key)]
                            }
                            
                            ${namespace}::edit \
                                -internal \
                                -handlers $handlers \
                                -operation "insert" \
                                -workflow_id $workflow_id \
                                -array child
                        }
                        unset missing_elm(child_${type})
                    }
                }

                # Check that there are no unknown attributes
                if { [llength [array names missing_elm]] > 0 && !$no_complain_p } {
                    error "Trying to set illegal action attributes: [join [array names missing_elm] ", "]"
                }
            }
        }

        if { !$internal_p } {
            workflow::definition_changed_handler -workflow_id $workflow_id
        }
    }

    return $action_id
}

ad_proc -public workflow::action::delete {
    {-action_id:required}
} {
    Delete action with given id.

    @author Peter Marklund
} {
    workflow::action::edit -operation "delete" -action_id $action_id
}

ad_proc -public workflow::action::get_assigned_role {
    {-action_id:required}
} {
    Return the assigned role of the given action
    @param action_id The action_id of the action.
    @return role_id of the assigned role.
} {
    return [get_from_request_cache $action_id "assigned_role_id"]
}

ad_proc -public workflow::action::get_allowed_roles {
    {-action_id:required}
} {
    Return the allowed roles of the given action
    @param action_id The action_id of the action.
    @return List of role_id of the allowed roles
} {
    return [get_from_request_cache $action_id "allowed_role_ids"]
}

ad_proc -public workflow::action::get_privileges {
    {-action_id:required}
} {
    Return the assigned role of the given action
    @param action_id The action_id of the action.
    @return List of privileges that give permission to do this action
} {
    return [get_from_request_cache $action_id "privileges"]
}

ad_proc -public workflow::action::get_id {
    {-workflow_id:required}
    {-short_name:required}
} {
    Return the action_id of the action with the given short_name in the given workflow.

    @param workflow_id The ID of the workflow
    @param short_name The short_name of the action
    @return action_id of the desired action, or the empty string if it can't be found.
} {
    workflow::action::refresh_request_cache $workflow_id
    global __workflow_action_data,${workflow_id}

    foreach action_id [set __workflow_action_data,${workflow_id}(action_ids)] {
        array set one_action [set __workflow_action_data,${workflow_id}($action_id)]
        
        if { [string equal $one_action(short_name) $short_name] } {
            return $action_id
        }
    }

    error "workflow::action::get_id: Action with short_name $short_name not found for workflow $workflow_id"
}

ad_proc -public workflow::action::get_workflow_id {
    {-action_id:required}
} {
    Lookup the workflow_id of a certain action_id.

    @author Peter Marklund
} {
    return [util_memoize \
            [list workflow::action::get_workflow_id_not_cached -action_id $action_id]]
}

ad_proc -private workflow::action::get_workflow_id_not_cached {
    {-action_id:required}
} {
    This is a proc that should only be used internally by the workflow
    API, applications should use workflow::action::get_workflow_id instead.

    @author Peter Marklund
} {
    return [db_string select_workflow_id {}]
}

ad_proc -public workflow::action::get {
    {-action_id:required}
    {-array:required}
} {
    Return information about an action with a given id.

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)

    @return The array will contain the following entries: 
            workflow_id, sort_order, short_name, pretty_name, 
            pretty_past_tense, assigned_role (short_name), assigned_role_id, 
            always_enabled_p, trigger_type, parent_action, parent_action_id, description, 
            description_mime_type values for an action.

    @see workflow::action::get_all_info
    @see workflow::action::get_all_info_not_cached
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    array set row [get_from_request_cache $action_id]
}

ad_proc -public workflow::action::get_element {
    {-action_id {}}
    {-one_id {}}
    {-element:required}
} {
    Return a single element from the information about a action.

    @param action_id The ID of the action

    @param one_id    Same as action_id, just used for consistency across roles/actions/states.

    @param element   The element you want

    @return          The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $action_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either action_id or one_id"
        }
        set action_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either action_id or one_id"
        }
    }
    get -action_id $action_id -array row
    return $row($element)
}

ad_proc -public workflow::action::callback_insert {
    {-action_id:required}
    {-name:required}
    {-sort_order {}}
} {
    Add a side-effect to an action.
    
    @param action_id The ID of the action.
    @param name Name of service contract implementation, in the form (impl_owner_name).(impl_name), 
    for example, bug-tracker.CaptureResolutionCode
    @param sort_order The sort_order for the rule. Leave blank to add to the end of the list
    
    @author Lars Pind (lars@collaboraid.biz)
} {

    db_transaction {

        # Get the impl_id
        set acs_sc_impl_id [workflow::service_contract::get_impl_id -name $name]

        # Get the sort order
        if { ![exists_and_not_null sort_order] } {
            set sort_order [db_string select_sort_order {}]
        }

        # Insert the callback
        db_dml insert_callback {}
    }

    set workflow_id [workflow::action::get_workflow_id -action_id $action_id]
    workflow::action::flush_cache -workflow_id $workflow_id

    return $acs_sc_impl_id
}

ad_proc -private workflow::action::get_callbacks {
    {-action_id:required}
    {-contract_name:required}
} {
    Return a list of implementation names for the callbacks of a given workflow action.

    @see workflow::case::role::get_callbacks

    @author Peter Marklund
} {
    array set callbacks [get_from_request_cache $action_id callbacks_array]
    set callback_ids [get_from_request_cache $action_id callback_ids]
    
    # Loop over the callbacks and return the impl_names of those with a matching
    # contract name
    set impl_names [list]
    foreach callback_id $callback_ids {
        array set one_callback $callbacks($callback_id)

        if { [string equal $one_callback(contract_name) $contract_name] } {
            lappend impl_names $one_callback(impl_name)            
        }
    }

    return $impl_names
}

ad_proc -private workflow::action::update_sort_order {
    {-workflow_id:required}
    {-sort_order:required}
} {
    Increase the sort_order of other actions, if the new sort_order is already taken.
} { 
    set sort_order_taken_p [db_string select_sort_order_p {}]
    if { $sort_order_taken_p } {
        db_dml update_sort_order {}
    }
}

ad_proc -public workflow::action::get_existing_short_names {
    {-workflow_id:required}
    {-ignore_action_id {}}
} {
    Returns a list of existing action short_names in this workflow.
    Useful when you're trying to ensure a short_name is unique, 
    or construct a new short_name that is guaranteed to be unique.

    @param ignore_action_id   If specified, the short_name for the given action will not be included in the result set.
} {
    set result [list]

    foreach action_id [workflow::get_actions -all -workflow_id $workflow_id] {
        if { [empty_string_p $ignore_action_id] || ![string equal $ignore_action_id $action_id] } {
            lappend result [workflow::action::get_element -action_id $action_id -element short_name]
        }
    }

    return $result
}

ad_proc -public workflow::action::generate_short_name {
    {-workflow_id:required}
    {-pretty_name:required}
    {-short_name {}}
    {-action_id {}}
} {
    Generate a unique short_name from pretty_name.
    
    @param action_id    If you pass in this, we will allow that action's short_name to be reused.
    
} {
    set existing_short_names [workflow::action::get_existing_short_names \
                                  -workflow_id $workflow_id \
                                  -ignore_action_id $action_id]
    
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
            error "Action with short_name '$short_name' already exists in this workflow."
        }
    }

    return $short_name
}

ad_proc -public workflow::action::get_ids {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the action_id's of all the actions in the workflow.
    
    @param workflow_id   The ID of the workflow

    @return              list of action_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Use cached data about actions
    array set action_data [workflow::action::get_all_info -workflow_id $workflow_id]

    if { $all_p } {
        return $action_data(action_ids)
    }
        
    set action_ids [list]
    foreach action_id $action_data(action_ids) {
        if { [workflow::action::get_element \
                  -action_id $action_id \
                  -element parent_action_id] == $parent_action_id } {
            lappend action_ids $action_id
        }
    }
    return $action_ids
}


ad_proc -public workflow::action::get_options {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get an options list of actions for use with form builder.
} {
    set result [list]
    foreach action_id [workflow::get_actions \
                           -all=$all_p \
                           -workflow_id $workflow_id \
                           -parent_action_id $parent_action_id] {
        workflow::action::get -action_id $action_id -array action
        lappend result [list $action(pretty_name) $action_id]
    }
    return $result
}

ad_proc -public workflow::action::pretty_name_unique_p {
    -workflow_id:required
    -pretty_name:required
    {-parent_action_id {}}
    {-action_id {}}
} {
    Check if suggested pretty_name is unique. 
    
    @return 1 if unique, 0 if not unique.
} {
    set exists_p [db_string name_exists { 
        select count(*) 
        from   workflow_actions
        where  workflow_id = :workflow_id
        and    pretty_name = :pretty_name
        and    (:parent_action_id is null or parent_action_id = :parent_action_id)
        and    (:action_id is null or action_id != :action_id)
    }]
    return [expr !$exists_p]
}




######################################################################
#
# workflow::action::fsm
#
######################################################################

ad_proc -public workflow::action::fsm::new {
    {-workflow_id:required}
    {-action_id {}}
    {-sort_order {}}
    {-short_name {}}
    {-pretty_name:required}
    {-pretty_past_tense {}}
    {-edit_fields {}}
    {-allowed_roles {}}
    {-assigned_role {}}
    {-privileges {}}
    {-enabled_states {}}
    {-assigned_states {}}
    {-enabled_state_ids {}}
    {-assigned_state_ids {}}
    {-new_state {}}
    {-new_state_id {}}
    {-callbacks {}}
    -initial_action_p
    {-always_enabled_p f}
    {-trigger_type user}
    {-parent_action {}}
    {-description {}}
    {-description_mime_type {}}
    {-timeout_seconds {}}
} {
    Add an action to a certain FSM (Finite State Machine) workflow. 
    This procedure invokes the generic workflow::action::new procedures 
    and does additional inserts for FSM specific information. See the 
    parameter documentation for the proc workflow::action::new.

    @return the new action_id.

    @see workflow::action::fsm::edit

    @author Peter Marklund
} {        
    # Wrapper for workflow::action::edit

    array set row [list]
    foreach col { 
        initial_action_p sort_order short_name pretty_name
        pretty_past_tense edit_fields allowed_roles assigned_role 
        privileges callbacks always_enabled_p description description_mime_type 
        timeout_seconds trigger_type parent_action
    } {
        if { [info exists $col] } {
            set row($col) [set $col]
        }
    }
    foreach elm { 
        new_state new_state_id
        enabled_states assigned_states
        enabled_state_ids assigned_state_ids
    } {
        if { [exists_and_not_null $elm] } {
            set row($elm) [set $elm]
        }
    }

    set action_id [workflow::action::fsm::edit \
                       -operation "insert" \
                       -action_id $action_id \
                       -workflow_id $workflow_id \
                       -array row]

    return $action_id
}

ad_proc -public workflow::action::fsm::edit {
    {-operation "update"}
    {-action_id {}}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
    {-handlers { 
        roles "workflow::role" 
        actions "workflow::action::fsm"
        states "workflow::state::fsm"
    }}
} {
    Edit an action. 

    Attributes: 

    <ul>
      <li>new_state_id
      <li>enabled_states
      <li>enabled_state_ids
      <li>enabled_actions
      <li>enabled_action_ids
      <li>child_states
    </ul>

    @param operation    insert, update, delete

    @param action_id    For update/delete: The action to update or delete. 
                        For insert: Optionally specify a pre-generated action_id for the action.

    @param workflow_id  For update/delete: Optionally specify the workflow_id. If not specified, we will execute a query to find it.
                        For insert: The workflow_id of the new action.
    
    @param array        For insert/update: Name of an array in the caller's namespace with attributes to insert/update.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @return action_id
    
    @see workflow::action::edit
} {
    switch $operation {
        update - delete {
            if { [empty_string_p $action_id] } {
                error "You must specify the action_id of the action to $operation."
            }
        }
        insert {}
        default {
            error "Illegal operation '$operation'"
        }
    }
    switch $operation {
        insert - update {
            upvar 1 $array org_row
            if { ![array exists org_row] } {
                error "Array $array does not exist or is not an array"
            }
            array set row [array get org_row]
        }
    }
    switch $operation {
        insert {
            if { [empty_string_p $workflow_id] } {
                error "You must supply workflow_id"
            }
        }
        update - delete {
            if { [empty_string_p $workflow_id] } {
                set workflow_id [workflow::action::get_element \
                                     -action_id $action_id \
                                     -element workflow_id]
            }
        }
    }

    # Parse column values
    switch $operation {
        insert - update {
            # Special-case: array entry new_state (short_name) and new_state_id (state_id) -- DB column is new_state (state_id)
            if { [info exists row(new_state)] } {
                if { [info exists row(new_state_id)] } {
                    error "You cannot supply both new_state (takes short_name) and new_state_id (takes state_id)"
                }
                if { ![empty_string_p $row(new_state)] } {
                    set row(new_state_id) [workflow::state::fsm::get_id \
                                               -workflow_id $workflow_id \
                                               -short_name $row(new_state)]
                } else {
                    set row(new_state_id) [db_null]
                }
                unset row(new_state)
            }

            set update_clauses [list]
            set insert_names [list]
            set insert_values [list]

            # Handle columns in the workflow_fsm_actions table
            foreach attr { 
                new_state_id
            } {
                if { [info exists row($attr)] } {
                    set varname attr_$attr
                    # Convert the Tcl value to something we can use in the query
                    switch $attr {
                        new_state_id {
                            set varname attr_new_state
                            set $varname $row($attr)
                            unset row($attr)
                            set attr new_state
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
                    if { [info exists row($attr)] } {
                        unset row($attr)
                    }
                }
            }

            if { [info exists row(enabled_states)] } {
                if { [info exists row(enabled_state_ids)] } {
                    error "You cannot supply both enabled_states and enabled_state_ids"
                }
                set row(enabled_state_ids) [list]
                foreach state_short_name $row(enabled_states) {
                    lappend row(enabled_state_ids) [workflow::state::fsm::get_id \
                                                        -workflow_id $workflow_id \
                                                        -short_name $state_short_name]
                }
                unset row(enabled_states)
            }
            if { [info exists row(assigned_states)] } {
                if { [info exists row(assigned_state_ids)] } {
                    error "You cannot supply both assigned_states and assigned_state_ids"
                }
                set row(assigned_state_ids) [list]
                foreach state_short_name $row(assigned_states) {
                    lappend row(assigned_state_ids) [workflow::state::fsm::get_id \
                                                        -workflow_id $workflow_id \
                                                        -short_name $state_short_name]
                }
                unset row(assigned_states)
            }

            # Handle auxillary rows
            array set aux [list]
            foreach attr { 
                enabled_state_ids assigned_state_ids
            } {
                if { [info exists row($attr)] } {
                    set aux($attr) $row($attr)
                    unset row($attr)
                }
            }
        }
    }
    
    db_transaction {
        # Base row
        set action_id [workflow::action::edit \
                           -internal \
                           -handlers $handlers \
                           -operation $operation \
                           -action_id $action_id \
                           -workflow_id $workflow_id \
                           -array row]

        # Verify insert/update
        switch $operation {
            insert - update {
                set row_exists_p [db_string row_exists_p { select count(*) from workflow_fsm_actions where action_id = :action_id }]
                if { $row_exists_p } {
                    set operation "update"
                } else {
                    set operation "insert"
                }
            }
        }

        # FSM action row
        switch $operation {
            insert {
                lappend insert_names action_id
                lappend insert_values :action_id

                db_dml insert_action "
                    insert into workflow_fsm_actions
                    ([join $insert_names ", "])
                    values
                    ([join $insert_values ", "])
                "
            }
            update {
                if { [llength $update_clauses] > 0 } {
                    db_dml update_action "
                        update workflow_fsm_actions
                        set    [join $update_clauses ", "]
                        where  action_id = :action_id
                    "
                }
            }
            delete {
                # Handled through cascading delete
            }
        }
        
        # Auxilliary rows
        switch $operation {
            insert - update {
                # Record in which states the action is enabled but not assigned
                if { [info exists aux(enabled_state_ids)] } {
                    set assigned_p "f"
                    db_dml delete_enabled_states {}
                    foreach enabled_state_id $aux(enabled_state_ids) {
                        db_dml insert_enabled_state {}
                    }
                    unset aux(enabled_state_ids)
                }
                
                # Record where the action is both enabled and assigned
                if { [info exists aux(assigned_state_ids)] } {
                    set assigned_p "t"
                    db_dml delete_enabled_states {}
                    foreach enabled_state_id $aux(assigned_state_ids) {
                        db_dml insert_enabled_state {}
                    }
                    unset aux(assigned_state_ids)
                }
            }
        }

        if { !$internal_p } {
            workflow::definition_changed_handler -workflow_id $workflow_id
        }
    }

    return $action_id
}

ad_proc -public workflow::action::fsm::delete {
    {-action_id:required}
} {
    Delete FSM action with given id.

    @author Peter Marklund
} {
    workflow::action::fsm::edit -operation delete -action_id $action_id
}

ad_proc -public workflow::action::fsm::get_new_state {
    {-action_id:required}
} {
    Return the ID of the new state for an action
    @param action_id The action_id of the action.
    @return The ID of the new state after executing this action, or the empty string if the action doesn't change the state.
} {
    return [workflow::action::get_from_request_cache $action_id "new_state_id"]
}

ad_proc -public workflow::action::fsm::get {
    {-action_id:required}
    {-array:required}
} {
    Return information about an action with a given id, including
    FSM-related info: enabled_states, enabled_state_ids, assigned_states, assigned_state_ids, new_state, new_state_id.

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row
    
    workflow::action::get -action_id $action_id -array row
}

ad_proc -public workflow::action::fsm::get_element {
    {-action_id {}}
    {-one_id {}}
    {-element:required}
} {
    Return element from information about an action with a given id, including
    FSM-related info such as 'enabled_in_states', and 'new_state'.

    Return a single element from the information about a action.

    @param action_id The ID of the action

    @param one_id    Same as action_id, just used for consistency across roles/actions/states.

    @param element   The element you want

    @return          The element you asked for

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $action_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either action_id or one_id"
        }
        set action_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either action_id or one_id"
        }
    }
    workflow::action::fsm::get -action_id $action_id -array row
    return $row($element)
}

ad_proc -public workflow::action::fsm::set_enabled_in_state {
    -action_id:required
    -state_id:required
    -enabled:boolean
    -assigned:boolean
    {-workflow_id {}}
} {
    Edit the enabled state of an action

    @param workflow_id Optionally provide the workflow_id. If not, this will be gotten from a query.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $workflow_id] } {
        set workflow_id [workflow::action::get_element \
                             -action_id $action_id \
                             -element workflow_id]
    }

    set currently_assigned_p [db_string enabled_p { 
        select assigned_p
        from   workflow_fsm_action_en_in_st
        where  action_id = :action_id
        and    state_id = :state_id
    } -default {}]

    set currently_enabled_p [expr ![empty_string_p $currently_assigned_p]]
    set currently_assigned_p [template::util::is_true $currently_assigned_p]

    set db_assigned_p [db_boolean $assigned_p]
    
    if { $currently_enabled_p != $enabled_p} {
        if { $enabled_p } {
            db_dml enabled {
                insert into workflow_fsm_action_en_in_st (action_id, state_id, assigned_p)
                values (:action_id, :state_id, :db_assigned_p)
            }
        } else {
            db_dml disable {
                delete 
                from   workflow_fsm_action_en_in_st 
                where  action_id = :action_id
                and    state_id = :state_id
            }
        }
    } elseif { $currently_assigned_p != $assigned_p } {
        db_dml update_assigned_p {
            update workflow_fsm_action_en_in_st 
            set    assigned_p = :db_assigned_p
            where  action_id = :action_id
            and    state_id = :state_id
        }
    }
    
    workflow::definition_changed_handler -workflow_id $workflow_id
}


    

#####
# Private procs
#####

ad_proc -private workflow::action::fsm::parse_spec {
    {-workflow_id:required}
    {-short_name:required}
    {-spec:required}
    {-parent_action_id {}}
} {
    Parse the spec for an individual action definition.

    @param workflow_id The id of the workflow to delete.
    @param short_name The short_name of the action
    @param spec The action spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Initialize array with default values
    array set action { 
        pretty_past_tense {} 
        edit_fields {}
        allowed_roles {} 
        assigned_role {} 
        privileges {} 
        always_enabled_p f 
        enabled_states {} 
        assigned_states {}
        new_state {} 
        trigger_type user
        callbacks {}
    }
    
    # Get the info from the spec
    foreach { key value } $spec {
        set action($key) [string trim $value]
    }
    set action(short_name) $short_name
    set action(parent_action_id) $parent_action_id

    # Create the action
    set action_id [workflow::action::fsm::edit \
                       -operation "insert" \
                       -workflow_id $workflow_id \
                       -array action]
}

ad_proc -private workflow::action::fsm::generate_spec {
    {-action_id {}}
    {-one_id {}}
    {-handlers {}}
} {
    Generate the spec for an individual action definition.

    @param action_id The id of the action to generate spec for.

    @param one_id    Same as action_id, just used for consistency across roles/actions/states.

    @return spec     The actions spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $action_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either action_id or one_id"
        }
        set action_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either action_id or one_id"
        }
    }

    get -action_id $action_id -array row

    # Get rid of elements that shouldn't go into the spec
    array unset row short_name 
    array unset row action_id
    array unset row workflow_id
    array unset row sort_order
    array unset row assigned_role_id
    array unset row new_state_id
    array unset row callbacks_array
    array unset row callback_ids
    array unset row allowed_roles_array
    array unset row allowed_role_ids
    array unset row enabled_state_ids
    array unset row assigned_state_ids
    array unset row parent_action
    array unset row parent_action_id

    foreach { type namespace } $handlers {
        # type is 'roles', 'actions', 'states', etc.

        # LARS: Ugly as hell with the string range to cut from 'actions' to 'action_ids'

        if { [info exists row(child_[string range $type 0 end-1]_ids)] } {
            set row(child_${type}) [list]
            foreach child_id $row(child_[string range $type 0 end-1]_ids) {
                set child_short_name [${namespace}::get_element \
                                          -one_id $child_id \
                                          -element short_name]
                set child_spec [${namespace}::generate_spec -one_id $child_id -handlers $handlers]
                lappend row(child_${type}) $child_short_name $child_spec
            }
            unset row(child_[string range $type 0 end-1]_ids)
        }
    }

    if { ![exists_and_not_null row(description)] } {
        array unset row description_mime_type
    }

    # Get rid of a few defaults
    array set defaults { 
        trigger_type user
        always_enabled_p f 
    }

    set spec [list]
    foreach name [lsort [array names row]] {
        if { ![empty_string_p $row($name)] && ![exists_and_equal defaults($name) $row($name)] } {
            lappend spec $name $row($name)
        }
    }

    return $spec
}

ad_proc -private workflow::action::flush_cache {
    {-workflow_id:required}
} {
    Flush all caches related to actions for the given
    workflow_id. Used internally by the workflow API only.

    @author Peter Marklund
} {
    # Flush the request cache
    global __workflow_action_data,${workflow_id}
    if { [info exists __workflow_action_data,${workflow_id}] } {
        foreach action_id [set __workflow_action_data,${workflow_id}(action_ids)] {
            global __workflow_one_action,$action_id
            
            if { [info exists __workflow_one_action,$action_id] } {
                unset __workflow_one_action,$action_id
            }
        }

        unset __workflow_action_data,${workflow_id}
    }

    # Flush the thread global cache
    util_memoize_flush [list workflow::action::get_all_info_not_cached -workflow_id $workflow_id]
}

ad_proc -private workflow::action::refresh_request_cache { workflow_id } {
    Initializes the cached array with information about actions for a certain workflow
    so that it can be reused within one request.

    @author Peter Marklund
} {
    global __workflow_action_data,${workflow_id}

    if { ![info exists __workflow_action_data,${workflow_id}] } {
        array set __workflow_action_data,${workflow_id} [workflow::action::get_all_info -workflow_id $workflow_id]
    }
}
    
ad_proc -private workflow::action::get_from_request_cache {
    action_id
    {element ""}
} {
    This provides some abstraction for the Workflow API cache
    and also some optimization - we only convert lists to 
    arrays once per request. Should be used internally
    by the workflow API only.

    @author Peter Marklund
} {
    # Get the cache with all actions
    set workflow_id [workflow::action::get_workflow_id -action_id $action_id]
    refresh_request_cache $workflow_id
    global __workflow_action_data,${workflow_id}

    array set workflow_data [workflow::action::get_all_info -workflow_id $workflow_id]

    # A single action
    set action_var_name __workflow_one_action,${action_id}
    global $action_var_name

    if { ![info exists $action_var_name] } {
        array set $action_var_name [set __workflow_action_data,${workflow_id}($action_id)]
    }

    if { [empty_string_p $element] } {
        return [array get $action_var_name]
    } else {
        return [set "${action_var_name}($element)"]
    }
}

ad_proc -private workflow::action::get_all_info {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only.
    Returns all information related to actions for a certain
    workflow instance. Uses util_memoize to cache values.

    @see workflow::action::get_all_info_not_cached

    @author Peter Marklund
} {
    return [util_memoize [list workflow::action::get_all_info_not_cached \
                              -workflow_id $workflow_id] [workflow::cache_timeout]]
}

ad_proc -private workflow::action::get_all_info_not_cached {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only and
    should not be invoked directly from application code. Returns
    all information related to actions for a certain workflow instance.
    Goes to the database on every invocation and should be used together
    with util_memoize.

    @author Peter Marklund
} {
    # We avoid nested db queries in this proc to enhance performance

    # This is where we will ultimately deliver the results
    array set action_data {}

    # This will be a list of all action_id's
    set action_ids [list]

    # Get basic action info
    db_foreach action_info {} -column_array action_row {
        # Cache the mapping action_id -> workflow_id
        util_memoize_seed \
                [list workflow::action::get_workflow_id_not_cached -action_id $action_row(action_id)] \
                $workflow_id

        set action_id $action_row(action_id)
        array set action_array_${action_id} {
            callbacks_array {}
            callbacks {}
            callback_ids {}
            allowed_roles {}
            allowed_role_ids {}
            allowed_roles_array {}
            privileges {}
            assigned_states {}
            assigned_state_ids {}
            enabled_states {}
            enabled_state_ids {}
            child_states {}
            child_state_ids {}
        }
        array set action_array_${action_id} [array get action_row]
        if { ![empty_string_p $action_row(parent_action_id)] } {
            lappend action_array_$action_row(parent_action_id)(child_action_ids) $action_id
            lappend action_array_$action_row(parent_action_id)(child_actions) $action_row(short_name)
        }
        lappend action_ids $action_id
    }
    
    foreach action_id $action_ids {
        if { ![info exists action_array_${action_id}(child_action_ids)] } {
            set action_array_${action_id}(child_action_ids) [list]
            set action_array_${action_id}(child_actios) [list]
        }
    }
    
    # Get child states
    foreach state_id [workflow::fsm::get_states -all -workflow_id $workflow_id] {
        workflow::state::fsm::get -state_id $state_id -array state_array
        if { ![empty_string_p $state_array(parent_action_id)] } {
            lappend action_array_$state_array(parent_action_id)(child_state_ids) $state_id
            lappend action_array_$state_array(parent_action_id)(child_states) $state_array(short_name)
        }
    }
    
    # Build a separate array for all action callbacks of the workflow

    # Columns: impl_id, impl_name, impl_owner_name, contract_name, action_id
    db_foreach action_callbacks {} -column_array callback_row {
        set action_id $callback_row(action_id)

        lappend actions_array_${action_id}(callbacks) \
                "$callback_row(impl_owner_name).$callback_row(impl_name)"
        lappend actions_array_${action_id}(callback_ids) $callback_row(impl_id)

        lappend actions_array_${action_id}(callbacks_array) \
            [list $callback_row(impl_id) [array get callback_row]]
    } 

    # Build an array for all allowed roles for all actions
    db_foreach action_allowed_roles {} -column_array allowed_role_row {
        set action_id $allowed_role_row(action_id)

        lappend action_array_${action_id}(allowed_roles) $allowed_role_row(short_name)
        lappend action_array_${action_id}(allowed_role_ids) $allowed_role_row(role_id)

        # The 'allowed_roles_array' entry is an array-list, keyed by role_id, with the value being 
        # an array-list of the information returned by this call
        lappend action_array_${action_id}(allowed_roles_array) \
            [list $allowed_role_row(role_id) [array get allowed_role_row]]
    }

    # Build an array  of privileges for all actions
    db_foreach select_privileges {} {
        lappend action_array_${action_id}(privileges) $privilege
    }

    # Build arrays of enabled and assigned state short names for all actions
    db_foreach action_enabled_in_states {} {
        if { [string equal $assigned_p "t"] } {
            lappend action_array_${action_id}(assigned_states) $short_name
            lappend action_array_${action_id}(assigned_state_ids) $state_id
        } else {
            lappend action_array_${action_id}(enabled_states) $short_name
            lappend action_array_${action_id}(enabled_state_ids) $state_id
        }
    }

    # Move everything from the action_array_${action_id} arrays into the cacheo
    foreach action_id $action_ids {
        set action_data($action_id) [array get action_array_${action_id}]
    }

    set action_data(action_ids) $action_ids

    return [array get action_data]
}

ad_proc -public workflow::action::fsm::get_ids {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the action_id's of all the actions in the workflow.
    
    @param workflow_id   The ID of the workflow

    @return              list of action_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [workflow::action::get_ids -all=$all_p -workflow_id $workflow_id -parent_action_id $parent_action_id]
}

