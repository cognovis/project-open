ad_library {
    Procedures in the workflow namespace.
    
    @creation-date 8 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow {}
namespace eval workflow::fsm {}
namespace eval workflow::service_contract {}

#####
#
#  workflow namespace
#
#####

ad_proc -public workflow::package_key {} {
    return "workflow"
}

ad_proc -public workflow::new {
    {-pretty_name:required}
    {-short_name {}}
    {-package_key:required}
    {-object_id {}}
    {-object_type "acs_object"}
    {-callbacks {}}
} {
    Creates a new workflow. For each workflow you must create an initial action
    (using the workflow::action::new proc) to be fired when a workflow case is opened.

    @param short_name  For referring to the workflow from Tcl code. Use Tcl variable syntax.

    @param pretty_name A human readable name for the workflow for use in the UI.

    @param package_key The package to which this workflow belongs

    @param object_id   The id of an ACS Object indicating the scope the workflow. 
                       Typically this will be the id of a package type or a package instance
                       but it could also be some other type of ACS object within a package, for example
                       the id of a bug in the Bug Tracker application.

    @param object_type The type of objects that the workflow will be applied to. Valid values are in the
                       acs_object_types table. The parameter is optional and defaults to acs_object.

    @param callbacks   List of names of service contract implementations of callbacks for the workflow in 
                       impl_owner_name.impl_name format.

    @return            New workflow_id.

    @author Peter Marklund
} {
    # Wrapper for workflow::edit

    foreach elm { short_name pretty_name package_key object_id object_type callbacks } {
        set row($elm) [set $elm]
    }

    set workflow_id [workflow::edit \
                     -operation "insert" \
                     -array row]

    return $workflow_id
}

ad_proc -public workflow::edit {
    {-operation "update"}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
    {-no_complain:boolean}
} {
    Edit a workflow.

    Attributes of the array are: 

    <ul>
      <li>short_name
      <li>pretty_name
      <li>object_id
      <li>package_key
      <li>object_type
      <li>description
      <li>description_mime_type
      <li>callbacks
      <li>context_id
      <li>creation_user
      <li>creation_ip
    </ul>

    @param operation    insert, update, delete

    @param workflow_id  For update/delete: The workflow to update or delete. 

    @param array        For insert/update: Name of an array in the caller's namespace with attributes to insert/update.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @param no_complain  Silently ignore extra attributes that we don't know how to handle. 
                        
    @return             workflow_id
    
    @see workflow::new

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {        
    switch $operation {
        update - delete {
            if { [empty_string_p $workflow_id] } {
                error "You must specify the workflow_id of the workflow to $operation."
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
            # Check that they didn't try to supply a workflow_id
            if { [info exists row(workflow_id)] } {
                error "Cannot supply a workflow_id when creating"
            }
            # Default short_name on insert
            if { ![info exists row(short_name)] } {
                set row(short_name) {}
            }
            # Default package_key
            if { ![info exists row(package_key)] } {
                if { [ad_conn isconnected] } {
                    set row(package_key) [ad_conn package_key]
                }
            }
            # Default creation_user and creation_ip
            if { ![info exists row(creation_user)] } {
                if { [ad_conn isconnected] } {
                    set row(creation_user) [ad_conn user_id]
                } else {
                    set row(creation_user) [db_null]
                }
            }
            if { ![info exists row(creation_ip)] } {
                if { [ad_conn isconnected] } {
                    set row(creation_ip) [ad_conn peeraddr]
                } else {
                    set row(creation_ip) [db_null]
                }
            }
            # Default object_type
            if { ![info exists row(object_type)] } {
                set row(object_type) "acs_object"
            }
            # Check required values
            foreach attr { pretty_name package_key object_id  } {
                if { ![info exists row($attr)] } {
                    error "$attr is required when creating a new workflow"
                }
            }
            # Default context_id
            if { ![info exists row(context_id)] } {
                set row(context_id) $row(object_id)
            }
            # These are used when validating/generating short_name
            set workflow_array(package_key) $row(package_key)
            set workflow_array(object_id) $row(object_id)
        }
        update {
            # These are used when validating/generating short_name
            if { [info exists row(package_key)] || ![info exists row(object_id)]  } {
                workflow::get -workflow_id $workflow_id -array workflow_array
            }
            if { [info exists row(package_key)] } {
                set workflow_array(package_key) $row(package_key)
            }
            if { [info exists row(object_id)]  } {
                set workflow_array(object_id) $row(object_id)
            }
        }
    }


    # Parse column values
    switch $operation {
        insert - update {
            set update_clauses [list]
            set insert_names [list]
            set insert_values [list]

            # Handle columns in the workflows table
            foreach attr { 
                short_name
                pretty_name
                object_id
                package_key
                object_type
                description
                description_mime_type
                creation_user
                creation_ip
                context_id
            } {
                if { [info exists row($attr)] } {
                    set varname attr_$attr
                    # Convert the Tcl value to something we can use in the query
                    switch $attr {
                        short_name {
                            if { ![exists_and_not_null row(pretty_name)] } {
                                if { [empty_string_p $row(short_name)] } {
                                    error "You cannot $operation with an empty short_name without also setting pretty_name"
                                } else {
                                    set row(pretty_name) {}
                                }
                            }
                            
                            set $varname [workflow::generate_short_name \
                                              -workflow_id $workflow_id \
                                              -pretty_name $row(pretty_name) \
                                              -short_name $row(short_name) \
                                              -package_key $workflow_array(package_key) \
                                              -object_id $workflow_array(object_id)]
                        }
                        default {
                            set $varname $row($attr)
                        }
                    }
                    # Add the column to the insert/update statement
                    switch $attr {
                        short_name - pretty_name - package_key - object_id - object_type {
                            switch $operation {
                                insert {
                                    # Handled by the PL/SQL call
                                }
                                update {
                                    lappend update_clauses "$attr = :$varname"
                                }
                            }
                        }
                        creation_user - creation_ip - context_id {
                            if { ![string equal $operation insert] } {
                                error "Cannot update creation_user, creation_ip, context_id"
                            }
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
        # Do the insert/update/delete
        switch $operation {
            insert {
                # Insert the workflow -- uses a PL/SQL call because it's an object
                set workflow_id [db_exec_plsql do_insert {}]

                # Deal with attributes not handled by the PL/SQL call
                if { [llength $update_clauses] > 0 } {
                    db_dml update_workflow "
                        update workflows
                        set    [join $update_clauses ", "]
                        where  workflow_id = :workflow_id
                    "
                }
            }
            update {
                if { [llength $update_clauses] > 0 } {
                    db_dml update_workflow "
                        update workflows
                        set    [join $update_clauses ", "]
                        where  workflow_id = :workflow_id
                    "
                }
            }
            delete {
                db_dml delete_workflow {
                    delete from workflows
                    where workflow_id = :workflow_id
                }
            }
        }

        switch $operation {
            insert - update {
                # Callbacks
                if { [info exists row(callbacks)] } {
                    db_dml delete_callbacks {
                        delete from workflow_callbacks
                        where  workflow_id = :workflow_id
                    }
                    foreach callback_name $row(callbacks) {
                        workflow::callback_insert \
                            -workflow_id $workflow_id \
                            -name $callback_name
                    }
                    unset missing_elm(callbacks)
                }

                # Check that there are no unknown attributes
                if { [llength [array names missing_elm]] > 0 && !$no_complain_p } {
                    error "Trying to set illegal workflow attributes: [join [array names missing_elm] ", "]"
                }
            }
        }
    }

    if { !$internal_p } {
        # Flush the workflow cache, as changing an workflow changes the entire workflow
        # e.g. initial_workflow_p, enabled_in_states.
        workflow::flush_cache -workflow_id $workflow_id
    }

    return $workflow_id
}

ad_proc -public workflow::exists_p {
    {-workflow_id:required}
} {
    Return 1 if the workflow with given id exists and 0 otherwise.
    This proc is currently not cached.
} {
    return [db_string do_select {}
}

ad_proc -public workflow::delete {
    {-workflow_id:required}
} {
    Delete a generic workflow and all data attached to it (states, actions etc.).

    @param workflow_id The id of the workflow to delete.

    @author Peter Marklund
} {
    workflow::flush_cache -workflow_id $workflow_id

    return [db_exec_plsql do_delete {}]
}

ad_proc -public workflow::get_id {
    {-package_key {}}
    {-object_id {}}
    {-short_name:required}
} {
    Get workflow_id by short_name and object_id. Provide either package_key
    or object_id.
    
    @param object_id The ID of the object the workflow's for (typically a package instance)
    @param package_key The key of the package workflow belongs to.
    @param short_name the short name of the workflow you want

    @return The id of the workflow or the empty string if no workflow was found.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set workflow_id [util_memoize [list workflow::get_id_not_cached \
                                       -package_key $package_key \
                                       -object_id $object_id \
                                       -short_name $short_name] [workflow::cache_timeout]]

    return $workflow_id
}

ad_proc -public workflow::get {
    {-workflow_id:required}
    {-array:required}
} {
    Return information about a workflow. Uses util_memoize
    to cache values from the database.

    @author Lars Pind (lars@collaboraid.biz)

    @param workflow_id ID of workflow
    @param array name of array in which the info will be returned
    @return An array list with keys workflow_id, short_name,
            pretty_name, object_id, package_key, object_type, 
            and callbacks.

} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    array set row \
            [util_memoize [list workflow::get_not_cached -workflow_id $workflow_id] [workflow::cache_timeout]]
}

ad_proc -public workflow::get_element {
    {-workflow_id:required}
    {-element:required}
} {
    Return a single element from the information about a workflow.

    @param workflow_id The ID of the workflow
    @return The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    get -workflow_id $workflow_id -array row
    return $row($element)
}

ad_proc -public workflow::get_roles {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the role_id's of all the roles in the workflow.
    
    @param workflow_id The ID of the workflow
    @return list of role_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [workflow::role::get_ids -all=$all_p -workflow_id $workflow_id -parent_action_id $parent_action_id]
}

ad_proc -public workflow::get_actions {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the action_id's of all the actions in the workflow.
    
    @param workflow_id The ID of the workflow
    @return list of action_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [workflow::action::get_ids -all=$all_p -workflow_id $workflow_id -parent_action_id $parent_action_id]
}

ad_proc -public workflow::definition_changed_handler {
    {-workflow_id:required}
} {
    Should be called when the workflow definition has changed while there are active cases.
    Will update the record of enabled actions in each of the case, so they reflect the new workflow.
} {
    workflow::flush_cache -workflow_id $workflow_id

    set case_ids [db_list select_cases { select case_id from workflow_cases where workflow_id = :workflow_id }]

    foreach case_id $case_ids {
        workflow::case::state_changed_handler \
            -case_id $case_id
    }
    
}


ad_proc -public workflow::get_existing_short_names {
    {-package_key:required}
    {-object_id {}}
    {-ignore_workflow_id {}}
} {
    Returns a list of existing workflow short_names for this package_key and object_id.
    Useful when you're trying to ensure a short_name is unique, 
    or construct a new short_name that is guaranteed to be unique.

    @param ignore_workflow_id   If specified, the short_name for the given workflow will not be included in the result set.
} {
    set result [list]

    db_foreach select_workflows {
        select workflow_id, 
               short_name
        from   workflows
        where  package_key = :package_key
        and    object_id = :object_id
    } {
        if { [empty_string_p $ignore_workflow_id] || ![string equal $ignore_workflow_id $workflow_id] } {
            lappend result $short_name
        }
    }

    return $result
}

ad_proc -public workflow::generate_short_name {
    {-package_key:required}
    {-object_id {}}
    {-pretty_name:required}
    {-short_name {}}
    {-workflow_id {}}
} {
    Generate a unique short_name from pretty_name, or verify uniqueness of a given short_name.
    
    @param workflow_id    If you pass in this, we will allow that workflow's short_name to be reused.

    @param short_name     Suggested short_name.    
} {
    set existing_short_names [workflow::get_existing_short_names \
                                  -package_key $package_key \
                                  -object_id $object_id \
                                  -ignore_workflow_id $workflow_id]
    
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
            error "Workflow with short_name '$short_name' already exists for this package_key and object_id."
        }
    }

    return $short_name
}

ad_proc -public workflow::generate_spec {
    {-workflow_id:required}
    {-workflow_handler "workflow"}
    {-handlers { 
        roles workflow::role 
        actions workflow::action
    }}
} {
    Generate a spec for a workflow in array list style.
    Note that calling this directly with the default arguments will bomb, because workflow::action doesn't implement the required API.
    
    @param workflow_id The id of the workflow to generate a spec for.
    
    @param handlers    An array-list with Tcl namespaces where handlers for various elements are defined.
                       The keys are identical to the keys in the spec, and the namespaces are where 
                       the procs to handle them are defined.

    @return The spec for the workflow.

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    workflow::get -workflow_id $workflow_id -array row

    set short_name $row(short_name)

    array unset row object_id
    array unset row workflow_id
    array unset row short_name
    array unset row callbacks_array
    array unset row callback_ids
    array unset row callback_impl_names
    array unset row initial_action
    array unset row initial_action_id

    if { ![exists_and_not_null row(description)] } {
        array unset row description_mime_type
    }

    set spec [list]

    # Output sorted, and with no empty elements
    foreach name [lsort [array names row]] {
        if { ![empty_string_p $row($name)] } {
            lappend spec $name $row($name)
        }
    }

    foreach { key namespace } $handlers {
        set subspec [list]
        
        foreach sub_id [${namespace}::get_ids -workflow_id $workflow_id] {
            set sub_short_name [${namespace}::get_element \
                                -one_id $sub_id \
                                -element short_name]
            set elm_spec [${namespace}::generate_spec -one_id $sub_id -handlers $handlers]
            
            lappend subspec $sub_short_name $elm_spec 
        }
        lappend spec $key $subspec
    }

    set spec [list $short_name $spec]

    return $spec
}

ad_proc -public workflow::clone {
    {-workflow_id:required}
    {-package_key {}}
    {-object_id {}}
    {-array {}}
    {-workflow_handler workflow}
} {
    Clones an existing FSM workflow. The clone must belong to either a package key or an object id.

    @param pretty_name   A human readable name for the workflow for use in the UI.

    @param object_id     The id of an ACS Object indicating the scope the workflow. 
                         Typically this will be the id of a package type or a package instance
                         but it could also be some other type of ACS object within a package, for example
                         the id of a bug in the Bug Tracker application.

    @param package_key   A package to which this workflow belongs

    @param array         The name of an array in the caller's namespace. Values in this array will 
                         override workflow attributes of the workflow being cloned.

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    if { ![empty_string_p $array] } {
        upvar 1 $array row
        set array row
    } 

    set spec [${workflow_handler}::generate_spec \
                  -workflow_id $workflow_id \
                  -workflow_handler $workflow_handler]
    
    set workflow_id [${workflow_handler}::new_from_spec \
                         -package_key $package_key \
                         -object_id $object_id \
                         -spec $spec \
                         -array $array]

    return $workflow_id
}

ad_proc -public workflow::new_from_spec {
    {-package_key {}}
    {-object_id {}}
    {-spec:required}
    {-array {}}
    {-workflow_handler workflow}
    {-handlers { 
        roles workflow::role 
        actions workflow::action
    }}
} {
    Create a new workflow from spec. Workflows must belong to either a package key or an object id.

    @param package_key   A package to which this workflow belongs

    @param object_id     The id of an ACS Object indicating the scope the workflow. 
                         Typically this will be the id of a package type or a package instance
                         but it could also be some other type of ACS object within a package, for example
                         the id of a bug in the Bug Tracker application.

    @param spec          The workflow spec

    @param array         The name of an array in the caller's namespace. Values in this array will 
                         override workflow attributes of the workflow being cloned.

    @return The ID of the workflow created

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    if { [llength $spec] > 2 } {
        # Create any additional (child) workflows first, so they're available when creating the main one below
        # Not passing in the array, not keeping the workflow_id
        ${workflow_handler}::new_from_spec \
            -package_key $package_key \
            -object_id $object_id \
            -spec [lrange $spec 2 end] \
            -workflow_handler $workflow_handler \
            -handlers $handlers
    }

    set short_name [lindex $spec 0]
    array set workflow_array [lindex $spec 1]
    
    # Override workflow attributes from the array
    if { ![empty_string_p $array] } {
        upvar 1 $array row
        foreach name [array names row] {
            if { [string equal $name short_name] } {
                set short_name $row($name)
            } else {
                set workflow_array($name) $row($name)
            }
        }
    }

    set workflow_id [workflow::parse_spec \
                         -package_key $package_key \
                         -object_id $object_id \
                         -short_name $short_name \
                         -spec [array get workflow_array] \
                         -workflow_handler $workflow_handler \
                         -handlers $handlers]

    # The lookup proc might have cached that there is no workflow
    # with the short name of the workflow we have now created so
    # we need to flush
    util_memoize_flush_regexp {^workflow::get_id_not_cached}    

    return $workflow_id
}

ad_proc -private workflow::parse_spec {
    {-short_name:required}
    {-package_key {}}
    {-object_id {}}
    {-spec:required}
    {-workflow_handler workflow}
    {-handlers { 
        roles workflow::role 
        actions workflow::action
    }}
} {
    Create workflow, roles, states, actions, etc., as appropriate

    @param workflow_id The id of the workflow to delete.
    @param spec The roles spec

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    # Default values
    array set workflow { 
        callbacks {}
        object_type {acs_object}
    }

    foreach { key value } $spec { 
        set workflow($key) [string trim $value]
    }

    # Override stuff in the spec with stuff provided as an argument here
    foreach var { short_name package_key object_id } {
        if { ![empty_string_p [set $var]] || ![exists_and_not_null workflow($var)] } {
            set workflow($var) [set $var]
        }
    }
    
    # Pull out the extra types, roles/actions/states, so we don't try to create the workflow with them
    array set aux [list]
    array set counter [list]
    array set remain [list]
    foreach { key namespace } $handlers {
        if { [info exists workflow($key)] } {
            set aux($key) $workflow($key)
            if { [info exists count($key)] } {
                incr remain($key)
            } else {
                set remain($key) 1
            }
            set counter($key) 0
            unset workflow($key)
        }
    }

    array set sub_id [list]

    db_transaction {
        # Create the workflow
        set workflow_id [${workflow_handler}::edit \
                             -internal \
                             -operation "insert" \
                             -array workflow]
    
        # Create roles/actions/states
        foreach { type namespace } $handlers {
            # type is 'roles', 'actions', 'states', etc.
            if { [info exists aux($type)] } {
                incr remain($type) -1
                incr counter($type)
                foreach { subshort_name subspec } $aux($type) {
                    # subshort_name is the short_name of a single role/action/state
                    array unset row
                    array set row $subspec
                    set row(short_name) $subshort_name

                    # string trim everything
                    foreach key [array names row] { 
                        set row($key) [string trim $row($key)]
                    }
    
                    set cmd [list ${namespace}::edit \
                                 -internal \
                                 -workflow_id $workflow_id \
                                 -handlers $handlers \
                                 -array row]

                    if { $counter($type) == 1 } {
                        lappend cmd -operation insert
                    } else {
                        lappend cmd -[string range $type 0 end-1]_id $sub_id(${type},${subshort_name})
                    }
                    if { $remain($type) == 0 } {
                        lappend cmd -no_complain
                    }

                    set sub_id(${type},${subshort_name}) [eval $cmd]

                    # Flush the cache after all creates
                    workflow::flush_cache -workflow_id $workflow_id
                }
            }
        }
    }
    
    return $workflow_id
}



#----------------------------------------------------------------------
# Private procs
#----------------------------------------------------------------------



ad_proc -private workflow::flush_cache {
    {-workflow_id:required}
} {
    Flush all cached data related to the given
    workflow instance.
} {
    # The workflow instance that we are flushing may be in the get_id lookup
    # cache so we have to flush it
    util_memoize_flush_regexp {^workflow::get_id_not_cached}

    # Flush workflow scalar attributes and workflow callbacks
    util_memoize_flush [list workflow::get_not_cached -workflow_id $workflow_id]

    # Delegating flushing of info related to roles, actions, and states
    workflow::role::flush_cache -workflow_id $workflow_id
    workflow::action::flush_cache -workflow_id $workflow_id
    workflow::state::flush_cache -workflow_id $workflow_id

    # Flush all workflow cases from the cache. We are flushing more than needed here
    # but this approach seems easier and faster than looping over a potentially big number
    # of cases mapped to the workflow in the database, only a few of which may actually be 
    # cached and need flushing
    workflow::case::flush_cache
}

ad_proc -private workflow::cache_timeout {} {
    Returns the timeout to give to util_memoize (max_age parameter)
    for all workflow level data. Should probably
    be an APM parameter.

    @author Peter Marklund
} {
    return ""
}

ad_proc -private workflow::get_id_not_cached {
    {-package_key {}}
    {-object_id {}}
    {-short_name:required}
} {
    Private proc not to be used by applications, use workflow::get_id
    instead.
} {
    if { [empty_string_p $package_key] } {
        if { [empty_string_p $object_id] } {
            if { [ad_conn isconnected] } {
                set package_key [ad_conn package_key]
                set query_name select_workflow_id_by_package_key
            } else {
                error "You must supply either package_key or object_id, or there must be a current connection"
            }
        } else {
            set query_name select_workflow_id_by_object_id
        }
    } else {
        if { [empty_string_p $object_id] } {
            set query_name select_workflow_id_by_package_key
        } else {
            error "You must supply only one of either package_key or object_id"
        }
    }

    return [db_string $query_name {} -default {}]
}

ad_proc -private workflow::get_not_cached {
    {-workflow_id:required}
} {
    Private procedure that should never be used by application code - use
    workflow::get instead.
    Returns info about the workflow in an array list. Always
    goes to the database.

    @see workflow::get

    @author Peter Marklund
} {
    db_1row workflow_info {} -column_array row

    set callbacks [list]
    set callback_ids [list]
    array set callback_impl_names [list]
    array set callbacks_array [list]

    db_foreach workflow_callbacks {} -column_array callback_row {
        lappend callbacks "$callback_row(impl_owner_name).$callback_row(impl_name)"
        lappend callback_ids $callback_row(impl_id)
        lappend callback_impl_names($callback_row(contract_name)) $callback_row(impl_name)
        set callbacks_array($callback_row(impl_id)) [array get callback_row]
    } 

    set row(callbacks) $callbacks
    set row(callback_ids) $callback_ids
    set row(callback_impl_names) [array get callback_impl_names]
    set row(callbacks_array) [array get callbacks_array]

    return [array get row]
}

ad_proc -private workflow::default_sort_order {
    {-workflow_id:required}
    {-table_name:required}
} {
    By default the sort_order will be the highest current sort order plus 1.
    This reflects the order in which states and actions are added to the 
    workflow starting with 1
    
    @author Peter Marklund
} {
    set max_sort_order [db_string max_sort_order {} -default 0]

    return [expr $max_sort_order + 1]
}

ad_proc -private workflow::callback_insert {
    {-workflow_id:required}
    {-name:required}
    {-sort_order {}}
} {
    Add a side-effect to a workflow.
    
    @param workflow_id The ID of the workflow.
    @param name Name of service contract implementation, in the form (impl_owner_name).(impl_name), 
    for example, bug-tracker.FormatLogTitle.
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

    # Flush workflow scalar attributes and workflow callbacks
    util_memoize_flush [list workflow::get_not_cached -workflow_id $workflow_id]

    return $acs_sc_impl_id
}

ad_proc -private workflow::get_callbacks {
    {-workflow_id:required}
    {-contract_name:required}
} {
    Return the implementation names for a certain contract and a 
    given workflow.

    @author Peter Marklund
} {
    array set callback_impl_names [workflow::get_element -workflow_id $workflow_id -element callback_impl_names]

    if { [info exists callback_impl_names($contract_name)] } {
        return $callback_impl_names($contract_name)
    } else {
        return {}
    }
}

ad_proc -public workflow::get_notification_links {
    {-workflow_id:required}
    {-case_id}
    {-return_url}
} {
    Return a links to sign up for notifications.
    @return A multirow with columns url, label, title
} {
    
}


#####
#
# workflow::fsm namespace
#
#####

ad_proc -public workflow::fsm::new_from_spec {
    {-package_key {}}
    {-object_id {}}
    {-spec:required}
    {-array {}}
} {
    Create a new workflow from spec. Workflows must belong to either a package key or an object id.

    @param package_key   A package to which this workflow belongs

    @param object_id     The id of an ACS Object indicating the scope the workflow. 
                         Typically this will be the id of a package type or a package instance
                         but it could also be some other type of ACS object within a package, for example
                         the id of a bug in the Bug Tracker application.

    @param spec          The workflow spec

    @param array         The name of an array in the caller's namespace. Values in this array will 
                         override workflow attributes of the workflow being cloned.

    @return The ID of the workflow created

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    if { ![empty_string_p $array] } {
        upvar 1 $array row
        set array row
    } 
    return [workflow::new_from_spec \
                -package_key $package_key \
                -object_id $object_id \
                -spec $spec \
                -array $array \
                -workflow_handler "workflow::fsm" \
                -handlers {
                    roles workflow::role 
                    actions workflow::action
                    states workflow::state::fsm
                    actions workflow::action::fsm
                }]
}

ad_proc -public workflow::fsm::clone {
    {-workflow_id:required}
    {-package_key {}}
    {-object_id {}}
    {-array {}}
} {
    Clones an existing FSM workflow. The clone must belong to either a package key or an object id.

    @param object_id     The id of an ACS Object indicating the scope the workflow. 
                         Typically this will be the id of a package type or a package instance
                         but it could also be some other type of ACS object within a package, for example
                         the id of a bug in the Bug Tracker application.

    @param package_key   A package to which this workflow belongs

    @param array         The name of an array in the caller's namespace. Values in this array will 
                         override workflow attributes of the workflow being cloned.

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    if { ![empty_string_p $array] } {
        upvar 1 $array row
        set array row
    } 
    return [workflow::clone \
                -workflow_id $workflow_id \
                -package_key $package_key \
                -object_id $object_id \
                -array $array \
                -workflow_handler workflow::fsm]

    return $workflow_id
}

ad_proc -public workflow::fsm::generate_spec {
    {-workflow_id:required}
    {-workflow_handler "workflow"}
    {-handlers {
        roles workflow::role 
        actions workflow::action::fsm
        states workflow::state::fsm
    }}
} {
    Generate a spec for a workflow in array list style.
    
    @param  workflow_id   The id of the workflow to generate a spec for.
    @return The spec for the workflow.

    @author Lars Pind (lars@collaboraid.biz)
    @see workflow::new
} {
    set spec [workflow::generate_spec \
                  -workflow_id $workflow_id \
                  -workflow_handler $workflow_handler \
                  -handlers $handlers]

    return $spec
}

ad_proc -public workflow::fsm::get_states {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the state_id's of all the states in the workflow. 
    
    @param workflow_id The ID of the workflow
    @return list of state_id's.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [workflow::state::fsm::get_ids -all=$all_p -workflow_id $workflow_id -parent_action_id $parent_action_id]
}

ad_proc -public workflow::fsm::get_initial_state {
    {-workflow_id:required}
} {
    Get the id of the state that a workflow case is in once it's
    started (after the initial action is fired).

    @author Peter Marklund
} {
    set initial_action_id [workflow::get_element \
            -workflow_id $workflow_id \
            -element initial_action_id]

    set initial_state [workflow::action::fsm::get_element \
            -action_id $initial_action_id \
            -element new_state_id]

    return $initial_state
}

ad_proc -public workflow::fsm::edit {
    {-operation "update"}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
} {
    if { ![empty_string_p $array] } {
        upvar 1 $array row
        set array row
    }

    return [workflow::edit \
                -operation $operation \
                -workflow_id $workflow_id \
                -array $array \
                -internal=$internal_p]
}







#####
#
#  workflow::service_contract
#
#####

ad_proc -public workflow::service_contract::role_default_assignees {} {
    return "[workflow::package_key].Role_DefaultAssignees"
}

ad_proc -public workflow::service_contract::role_assignee_pick_list {} {
    return "[workflow::package_key].Role_AssigneePickList"
}

ad_proc -public workflow::service_contract::role_assignee_subquery {} {
    return "[workflow::package_key].Role_AssigneeSubQuery"
}

ad_proc -public workflow::service_contract::action_side_effect {} {
    return "[workflow::package_key].Action_SideEffect"
}

ad_proc -public workflow::service_contract::activity_log_format_title {} {
    return "[workflow::package_key].ActivityLog_FormatTitle"
}

ad_proc -public workflow::service_contract::notification_info {} {
    return "[workflow::package_key].NotificationInfo"
}

ad_proc -public workflow::service_contract::get_impl_id {
    {-name:required}
} {
    set namev [split $name "."]

    return [acs_sc::impl::get_id -owner [lindex $namev 0] -name [lindex $namev 1]]
}
