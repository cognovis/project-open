ad_library {
    Procedures in the workflow::role namespace.
    
    @creation-date 8 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::role {}




#####
#
#  workflow::role namespace
#
#####

ad_proc -public workflow::role::new {
    {-workflow_id:required}
    {-role_id {}}
    {-short_name {}}
    {-pretty_name:required}
    {-sort_order {}}
    {-callbacks {}}
} {
    Creates a new role for a workflow.
    
    @param workflow_id  The ID of the workflow the new role belongs to
    @param short_name   The short_name of the new role
    @param pretty_name  The pretty name of the new role
    @param callbacks    A list of names service-contract implementations.
    @return             role_id
    
    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {        
    # Wrapper for workflow::role::edit

    foreach elm { short_name pretty_name sort_order callbacks } {
        set row($elm) [set $elm]
    }

    set role_id [workflow::role::edit \
                     -operation "insert" \
                     -role_id $role_id \
                     -workflow_id $workflow_id \
                     -array row]

    return $role_id
}

ad_proc -public workflow::role::edit {
    {-operation "update"}
    {-role_id {}}
    {-workflow_id {}}
    {-array {}}
    {-internal:boolean}
    {-no_complain:boolean}
    {-handlers {}}
} {
    Edit a workflow role. 

    Attributes of the array are: 

    short_name
    pretty_name
    sort_order
    callbacks.

    @param operation    insert, update, delete

    @param role_id      For update/delete: The role to update or delete. 
                        For insert: Optionally specify a pre-generated role_id for the role.

    @param workflow_id  For update/delete: Optionally specify the workflow_id. If not specified, we will execute a query to find it.
                        For insert: The workflow_id of the new role.
    
    @param array        For insert/update: Name of an array in the caller's namespace with attributes to insert/update.

    @param internal     Set this flag if you're calling this proc from within the corresponding proc 
                        for a particular workflow model. Will cause this proc to not flush the cache 
                        or call workflow::definition_changed_handler, which the caller must then do.

    @param no_complain  Silently ignore extra attributes that we don't know how to handle. 
                        
    @return             role_id
    
    @see workflow::role::new

    @author Peter Marklund
    @author Lars Pind (lars@collaboraid.biz)
} {        
    switch $operation {
        update - delete {
            if { [empty_string_p $role_id] } {
                error "You must specify the role_id of the role to $operation."
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
                                         -table_name "workflow_roles"]
            }
            # Default short_name on insert
            if { ![info exists row(short_name)] } {
                set row(short_name) {}
            }
        }
        update {
            if { [empty_string_p $workflow_id] } {
                set workflow_id [workflow::role::get_element \
                                     -role_id $role_id \
                                     -element workflow_id]
            }
        }
    }

    # Parse column values
    switch $operation {
        insert - update {
            set update_clauses [list]
            set insert_names [list]
            set insert_values [list]

            # Handle columns in the workflow_roles table
            foreach attr { 
                short_name pretty_name sort_order 
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
                            
                            set $varname [workflow::role::generate_short_name \
                                              -workflow_id $workflow_id \
                                              -pretty_name $row(pretty_name) \
                                              -short_name $row(short_name) \
                                              -role_id $role_id]
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
        }
    }
    
    db_transaction {
        # Sort_order
        switch $operation {
            insert - update {
                if { [info exists row(sort_order)] } {
                    workflow::role::update_sort_order \
                        -workflow_id $workflow_id \
                        -sort_order $row(sort_order)
                }
            }
        }
        # Do the insert/update/delete
        switch $operation {
            insert {
                if { [empty_string_p $role_id] } {
                    set role_id [db_nextval "workflow_roles_seq"]
                }

                lappend insert_names role_id
                lappend insert_values :role_id
                lappend insert_names workflow_id
                lappend insert_values :workflow_id

                db_dml insert_role "
                    insert into workflow_roles
                    ([join $insert_names ", "])
                    values
                    ([join $insert_values ", "])
                "
            }
            update {
                if { [llength $update_clauses] > 0 } {
                    db_dml update_role "
                        update workflow_roles
                        set    [join $update_clauses ", "]
                        where  role_id = :role_id
                    "
                }
            }
            delete {
                db_dml delete_role {
                    delete from workflow_roles
                    where role_id = :role_id
                }
            }
        }

        switch $operation {
            insert - update {
                # Callbacks
                if { [info exists row(callbacks)] } {
                    db_dml delete_callbacks {
                        delete from workflow_role_callbacks
                        where  role_id = :role_id
                    }
                    foreach callback_name $row(callbacks) {
                        workflow::role::callback_insert \
                            -role_id $role_id \
                            -name $callback_name
                    }
                    unset missing_elm(callbacks)
                }

                # Check that there are no unknown attributes
                if { [llength [array names missing_elm]] > 0 && !$no_complain } {
                    error "Trying to set illegal role attributes: [join [array names missing_elm] ", "]"
                }
            }
        }

        if { !$internal_p } {
            workflow::definition_changed_handler -workflow_id $workflow_id
        }
    }

    return $role_id
}

ad_proc -public workflow::role::delete {
    {-role_id:required}
} {
    Delete workflow role with given id.

    @author Peter Marklund
} {
    workflow::role::edit \
        -operation "delete" \
        -role_id $role_id
}

ad_proc -public workflow::role::get_options {
    {-workflow_id:required}
    {-id_values:boolean}
} {
    Get a list of roles in a workflow for use in the 'options' property of a form builder form element.

    @param id_values Provide this switch if you want the values in the options list to be role id:s instead
                   of short names.
                   

    @author Lars Pind (lars@collaboraid.biz)
} {
    set result [list]

    # workflow::get_roles returns the roles in sort_order
    foreach role_id [workflow::get_roles -workflow_id $workflow_id] {
        workflow::role::get -role_id $role_id -array row
        if { $id_values_p } {
            lappend result [list $row(pretty_name) $role_id]
        } else {
            lappend result [list $row(pretty_name) $row(short_name)]
        }
    }
    return $result
}

ad_proc -public workflow::role::get_id {
    {-workflow_id:required}
    {-short_name:required}
} {
    Return the role_id of the role with the given short_name in the given workflow.

    @param workflow_id The ID of the workflow
    @param short_name The short_name of the role
    @return role_id of the desired role, or the empty string if it can't be found.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Get role info from cache
    array set role_data [workflow::role::get_all_info -workflow_id $workflow_id]

    foreach role_id $role_data(role_ids) {
        array set one_role $role_data($role_id)
        
        if { [string equal $one_role(short_name) $short_name] } {
            return $one_role(role_id)
        }
    }
    
    error "workflow::role::get_id role with short_name $short_name not found for workflow $workflow_id"
}

ad_proc -public workflow::role::get_workflow_id {
    {-role_id:required}
} {
    Lookup the workflow_id of a certain role_id.

    @author Peter Marklund
} {
    return [util_memoize \
            [list workflow::role::get_workflow_id_not_cached -role_id $role_id]]
}

ad_proc -private workflow::role::get_workflow_id_not_cached {
    {-role_id:required}
} {
    This is a proc that should only be used internally by the workflow
    API, applications should use workflow::role::get_workflow_id instead.

    @author Peter Marklund
} {
    return [db_string select_workflow_id {}]
}

ad_proc -public workflow::role::get {
    {-role_id:required}
    {-array:required}
} {
    Return information about a role in an array.

    @param role_id The ID of the workflow
    @param array Name of the array you want the info returned in

    @Author Lars Pind (lars@collaboraid.biz)
} {
    set workflow_id [workflow::role::get_workflow_id -role_id $role_id]

    upvar $array row

    # Get info about all roles for this workflow
    array set role_data [workflow::role::get_all_info -workflow_id $workflow_id]

    array set row $role_data($role_id)
}

ad_proc -public workflow::role::get_element {
    {-role_id {}}
    {-one_id {}}
    {-element:required}
} {
    Return a single element from the information about a role.

    @param role_id  The id of the role to get an element for.

    @param one_id   Same as role_id, just used for consistency across roles/actions/states.

    @return element The element you asked for

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $role_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either role_id or one_id"
        }
        set role_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either role_id or one_id"
        }
    }
    get -role_id $role_id -array row
    return $row($element)
}

ad_proc -private workflow::role::get_callbacks {
    {-role_id:required}
    {-contract_name:required}
} {
    Get the impl_names of callbacks of a given contract for a given role.
    
    @param role_id the ID of the role to assign.
    @param contract_name the name of the contract

    @author Lars Pind (lars@collaboraid.biz)
} {
    array set callback_impl_names [get_element -role_id $role_id -element callback_impl_names]

    if { [info exists callback_impl_names($contract_name)] } {
        return $callback_impl_names($contract_name)
    } else {
        return {}
    }
}

ad_proc -private workflow::role::parse_spec {
    {-workflow_id:required}
    {-short_name:required}
    {-spec:required}
} {
    Parse the spec for an individual role definition.

    @param workflow_id The id of the workflow the role should be added to.
    @param short_name The short_name of the role
    @param spec The roles spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Initialize array with default values
    array set role { callbacks {} }
    
    # Get the info from the spec
    foreach { key value } $spec {
        set role($key) [string trim $value]
    }

    # Create the role
    set role_id [workflow::role::new \
            -workflow_id $workflow_id \
            -short_name $short_name \
            -pretty_name $role(pretty_name) \
            -callbacks $role(callbacks)
            ]
}

ad_proc -private workflow::role::generate_spec {
    {-role_id {}}
    {-one_id {}}
    {-handlers {}}
} {
    Generate the spec for an individual role definition.

    @param role_id  The id of the role to generate spec for.

    @param one_id   Same as role_id, just used for consistency across roles/actions/states.

    @return spec    The roles spec

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $role_id] } {
        if { [empty_string_p $one_id] } {
            error "You must supply either role_id or one_id"
        }
        set role_id $one_id
    } else {
        if { ![empty_string_p $one_id] } {
            error "You can only supply either role_id or one_id"
        }
    }

    get -role_id $role_id -array row

    # Get rid of elements that shouldn't go into the spec
    array unset row short_name 
    array unset row role_id
    array unset row workflow_id
    array unset row sort_order
    array unset row role_ids
    array unset row callbacks_array
    array unset row callback_ids
    array unset row callback_impl_names

    set spec {}
    foreach name [lsort [array names row]] {
        if { ![empty_string_p $row($name)] } {
            lappend spec $name $row($name)
        }
    }

    return $spec
}

ad_proc -private workflow::role::get_ids {
    {-all:boolean}
    {-workflow_id:required}
    {-parent_action_id {}}
} {
    Get the IDs of all the roles in the right order.

    @param workflow_id The id of the workflow to get roles for.
    
    @param parent_action_id No meaning. Provided for compatibility with similar procs for actions and states.

    @return A list of role IDs.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # Use cached data about roles
    array set role_data [workflow::role::get_all_info -workflow_id $workflow_id]
    return $role_data(role_ids)
}

ad_proc -public workflow::role::callback_insert {
    {-role_id:required}
    {-name:required}
    {-sort_order}
} {
    Add an assignment rule to a role.
    
    @param role_id The ID of the role
    @param name Name of service contract implementation, in the form (impl_owner_name).(impl_name), 
    for example, bug-tracker.ComponentMaintainer.
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

        # Insert the rule
        db_dml insert_callback {}
    }

    set workflow_id [workflow::role::get_workflow_id -role_id $role_id]
    workflow::role::flush_cache -workflow_id $workflow_id

    return $acs_sc_impl_id
}

ad_proc -private workflow::role::flush_cache {
    {-workflow_id:required}
} {
    Flush all caches related to roles for the given
    workflow. Used internally by the workflow API only.

    @author Peter Marklund
} {
    # TODO: Flush request cache
    # no request cache to flush yet

    # Flush the thread global cache
    util_memoize_flush [list workflow::role::get_all_info_not_cached -workflow_id $workflow_id]    
}

ad_proc -private workflow::role::get_all_info {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only.
    Returns all information related to roles for a certain
    workflow instance. Uses util_memoize to cache values.

    @see workflow::role::get_all_info_not_cached

    @author Peter Marklund
} {
    return [util_memoize [list workflow::role::get_all_info_not_cached \
            -workflow_id $workflow_id] [workflow::cache_timeout]]
}

ad_proc -private workflow::role::get_all_info_not_cached {
    {-workflow_id:required}
} {
    This proc is for internal use in the workflow API only and
    should not be invoked directly from application code. Returns
    all information related to roles for a certain workflow instance.
    Goes to the database on every invocation and should be used together
    with util_memoize.

    @author Peter Marklund
} {
    # For performance we avoid nested queries in this proc
    set role_ids [list]

    db_foreach role_info {} -column_array row {
        set role_id $row(role_id)

        lappend role_ids $role_id

        # store in role,$role_id arrays
        foreach name [array names row] {
            set role,${role_id}($name) $row($name)
        }

        # Cache the mapping role_id -> workflow_id
        util_memoize_seed \
                [list workflow::role::get_workflow_id_not_cached -role_id $role_id] \
                $workflow_id
    }
    
    # Get the callbacks of all roles of the workflow
    foreach role_id $role_ids {
        set role,${role_id}(callbacks) {}
        set role,${role_id}(callback_ids) {}
        array set callback_impl_names,$role_id [list]
        array set callbacks_array,$role_id [list]
    }

    db_foreach role_callbacks {} -column_array row {
        set role_id $row(role_id)

        lappend role,${role_id}(callbacks) "$row(impl_owner_name).$row(impl_name)"
        lappend role,${role_id}(callback_ids) $row(impl_id)

        lappend callback_impl_names,${role_id}(${row(contract_name)}) $row(impl_name)
        set callbacks_array,${role_id}($row(impl_id)) [array get row]
    } 
    if { [info exists row] } {
        unset row
    }

    foreach role_id $role_ids {
        set role,${role_id}(callback_impl_names) [array get callback_impl_names,$role_id]
        set role,${role_id}(callbacks_array) [array get callbacks_array,$role_id]
    }

    # Build up the master role_data array
    foreach role_id $role_ids {
        set role_data($role_id) [array get role,$role_id]
    }

    set role_data(role_ids) $role_ids

    return [array get role_data]
}

ad_proc -private workflow::role::update_sort_order {
    {-workflow_id:required}
    {-sort_order:required}
} {
    Increase the sort_order of other roles, if the new sort_order is already taken.
} { 
    set sort_order_taken_p [db_string select_sort_order_p {}]
    if { $sort_order_taken_p } {
        db_dml update_sort_order {}
    }
}

ad_proc -public workflow::role::get_existing_short_names {
    {-workflow_id:required}
    {-ignore_role_id {}}
} {
    Returns a list of existing role short_names in this workflow.
    Useful when you're trying to ensure a short_name is unique, 
    or construct a new short_name that is guaranteed to be unique.

    @param ignore_role_id   If specified, the short_name for the given role will not be included in the result set.
} {
    set result [list]

    foreach role_id [workflow::get_roles -all -workflow_id $workflow_id] {
        if { [empty_string_p $ignore_role_id] || ![string equal $ignore_role_id $role_id] } {
            lappend result [workflow::role::get_element -role_id $role_id -element short_name]
        }
    }

    return $result
}

ad_proc -public workflow::role::generate_short_name {
    {-workflow_id:required}
    {-pretty_name:required}
    {-short_name {}}
    {-role_id {}}
} {
    Generate a unique short_name from pretty_name.
    
    @param role_id    If you pass in this, we will allow that role's short_name to be reused.
    
} {
    set existing_short_names [workflow::role::get_existing_short_names \
                                  -workflow_id $workflow_id \
                                  -ignore_role_id $role_id]
    
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
            error "Role with short_name '$short_name' already exists in this workflow."
        }
    }

    return $short_name
}
