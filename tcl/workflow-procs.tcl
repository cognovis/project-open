ad_library {
    Tcl-API for the workflow engine.

    @author Lars Pind (lars@pinds.com)
    @creation-date 13 July 2000
    @cvs-id $Id$
}



ad_proc -public wf_task_list {
    {-date_format "Mon fmDDfm, YYYY HH24:MI:SS"}
    {-user_id ""}
    {-type enabled}
} {
    Get information about the tasks are on a user's work list.

    <p>
    
    @param user_id is the user for which we're listing tasks. If you
    don't provide a user_id or
    you provide an empty string for user_id, then we'll use the
    user_id of the currently logged-in user.

    @param date_format Use this to customize the date-format
    used. Must be a valid Oracle date format specification.
    
    @param type is either <code>enabled</code> or <code>own</code>:
    <dl>
    <dt><code>enabled</code>
    <dd>Returns the list of tasks that are ready to execute, but not
    started by anyone yet. 
    <dt><code>own</code>
    <dd>Returns the list of tasks currently started and held by the given user.
    </dl>
    
    @return a Tcl list of information about the tasks that are
    executable by the given user, ordered by their priority.
    <p>
    Each element of the list is an [array get] representation with the following 
    keys: task_id, case_id, transition_key, task_name, enabled_date, enabled_date_pretty,
    started_date, started_date_pretty, deadline, deadline_pretty, state, object_id, object_type, object_type_pretty,
    object_name, estimated_minutes, sysdate. 
    
    <p>
    
    Sysdate is provided, so you can calculate the number of days
    between now and any of the other dates provided.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    if { ![string equal $type enabled] && ![string equal $type own] } {
        return -code error "Unrecognized type: Type can be 'enabled' or 'own'"
    }

    if { [empty_string_p $user_id] } {
        set user_id [ad_get_user_id]
        if { $user_id == 0 } { 
            return {}
        }
    }

    set select {
        {t.task_id} 
        {t.case_id} 
        {t.transition_key} 
        {t.transition_name as task_name} 
        {t.enabled_date} 
        {to_char(t.enabled_date, :date_format) as enabled_date_pretty}
        {t.started_date}
        {to_char(t.started_date, :date_format) as started_date_pretty}
        {t.deadline}
        {to_char(t.deadline, :date_format) as deadline_pretty}
        {t.deadline - sysdate as days_till_deadline}
        {t.state} 
        {c.object_id} 
        {ot.object_type as object_type}
        {ot.pretty_name as object_type_pretty} 
        {acs_object.name(c.object_id) as object_name}
        {t.estimated_minutes}
        {c.workflow_key}
        {wft.pretty_name as workflow_name}
        {sysdate}
    }
    set from {
        {wf_user_tasks t} 
        {wf_cases c} 
        {acs_objects o} 
        {acs_object_types ot}
        {acs_object_types wft}
    }
    set where {
        {t.user_id = :user_id} 
        {c.case_id = t.case_id} 
        {c.object_id = o.object_id} 
        {ot.object_type = o.object_type}
        {wft.object_type = c.workflow_key}
    }
    
    switch $type {
        enabled {
            lappend where {t.state = 'enabled'}
        }
        own {
            lappend from {users u}
            lappend where {t.state = 'started'} {t.holding_user = t.user_id} {u.user_id = t.user_id}
        }
    }

    set sql "
select [join $select ",\n       "]
from   [join $from ",\n       "]
where  [join $where "\n   and "]"

    db_foreach user_tasks $sql -column_array row {
        lappend result [array get row]
    } if_no_rows {
        set result [list]
    }
    return $result
}


ad_proc -public wf_case_info { 
    case_id
} {
    Get information about a case.

    @return A list in array get format with the following keys: case_id, object_name, state.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    db_1row case {
        select case_id,
               acs_object.name(object_id) as object_name,
        
               state
        from   wf_cases
        where  case_id = :case_id
    } -column_array case
        
    return [array get case]
}


ad_proc -public wf_task_info {
    {-date_format "Mon fmDDfm, YYYY HH24:MI:SS"}
    task_id
} {
    Get detailed information about one task.
    
    @param date_format Use this to customize the date-format
    used. Must be a valid Oracle date format specification.

    @return an <code>[array get]</code> representation with the following keys: 
    <code>task_id, case_id, object_id, object_name, object_type_pretty, workflow_key, task_name,
    state, state_pretty, enabled_date, enabled_date_pretty, started_date, started_date_pretty, 
    canceled_date, canceled_date_pretty, finished_date, finished_date_pretty,
    overridden_date, overridden_date_pretty, holding_user, holding_user_name, 
    holding_user_email, hold_timeout, hold_timeout_pretty, deadline, deadline_pretty, days_till_deadline
    estimated_minutes, instructions, sysdate, journal, attributes_to_set, assigned_users, 
    this_user_is_assigned_p, roles_to_assign</code>.

    <p>

    The values for the keys <code>journal, attributes_to_set and assigned_users</code>
    are themselves Tcl lists of <code>[array
    get]</code> repesentations. For the journal entry, see <a
    href="/api-doc/proc-view?proc=wf_journal"><code>wf_journal</code></a>.
    
    <p>

    The key <code>attribute_to_set</code> contains these keys: <code>attribute_id, attribute_name, 
    pretty_name, datatype, value, wf_datatype</code>.

    <p>

    The key <code>assigned_users</code> contains these keys: <code>user_id, name, email</code>.
    
    <p>

    The key <code>transitions_to_assign</code> contains these keys: <code>transition_key, transition_name</code>

    <p>

    
    Sysdate is provided, so you can calculate the number of days
    between now and any of the other dates provided.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    db_1row task {
        select t.task_id,
               t.case_id, 
               c.object_id,
               acs_object.name(c.object_id) as object_name,
               ot.pretty_name as object_type_pretty,
               c.workflow_key,
               tr.transition_name as task_name, 
               tr.instructions,
               t.state, 
               t.enabled_date,
               to_char(t.enabled_date, :date_format) as enabled_date_pretty,
               t.started_date,
               to_char(t.started_date, :date_format) as started_date_pretty,
               t.canceled_date,
               to_char(t.canceled_date, :date_format) as canceled_date_pretty,
               t.finished_date,
               to_char(t.finished_date, :date_format) as finished_date_pretty,
               t.overridden_date,
               to_char(t.overridden_date, :date_format) as overridden_date_pretty,
               t.holding_user, 
               acs_object.name(t.holding_user) as holding_user_name,
               p.email as holding_user_email,
               t.hold_timeout,
               to_char(t.hold_timeout, :date_format) as hold_timeout_pretty,
               t.deadline,
               to_char(t.deadline, :date_format) as deadline_pretty,
               t.deadline - sysdate as days_till_deadline,
               tr.estimated_minutes,
               sysdate
          from wf_tasks t, 
               wf_cases c, 
               wf_transition_info tr, 
               acs_objects o, 
               acs_object_types ot, 
               parties p
         where t.task_id = :task_id
           and c.case_id = t.case_id
           and tr.transition_key = t.transition_key
           and tr.workflow_key = t.workflow_key and tr.context_key = c.context_key
           and o.object_id = c.object_id
           and ot.object_type = o.object_type
           and p.party_id (+) = t.holding_user
    } -column_array task

    set task(state_pretty) [wf_task_state_pretty $task(state)]

    db_multirow task_attributes_to_set task_attributes_to_set {
        select a.attribute_id,
               a.attribute_name, 
               a.pretty_name, 
               a.datatype, 
               acs_object.get_attribute(t.case_id, a.attribute_name) as value,
               '' as attribute_widget
          from acs_attributes a, wf_transition_attribute_map m, wf_tasks t
         where t.task_id = :task_id
           and m.workflow_key = t.workflow_key and m.transition_key = t.transition_key
           and a.attribute_id = m.attribute_id
         order by m.sort_order
    } { 
        set attribute_widget [wf_attribute_widget \
                [list attribute_id $attribute_id \
                attribute_name $attribute_name \
                pretty_name $pretty_name \
                datatype $datatype \
                value $value]]
    }

    db_multirow task_roles_to_assign task_roles_to_assign {
        select r.role_key, 
               r.role_name,
               '' as assignment_widget
          from wf_tasks t, wf_transition_role_assign_map tram, wf_roles r
         where t.task_id = :task_id
           and tram.workflow_key = t.workflow_key and tram.transition_key = t.transition_key
           and r.workflow_key = tram.workflow_key and r.role_key = tram.assign_role_key
        order by r.sort_order
    } {
        set assignment_widget [wf_assignment_widget -case_id $task(case_id) $role_key]
    }

    db_multirow task_assigned_users task_assigned_users {
        select ut.user_id,
               acs_object.name(ut.user_id) as name,
               p.email as email
          from wf_user_tasks ut, parties p
         where ut.task_id = :task_id
           and p.party_id = ut.user_id
    }

    set user_id [ad_get_user_id]
    if { [string equal $task(state) enabled] } {
        set task(this_user_is_assigned_p) [db_string this_user_is_assigned_p { 
            select count(*) from wf_user_tasks  where task_id = :task_id and user_id = :user_id
        }]
    } else {
        if { ![empty_string_p $task(holding_user)] && $user_id == $task(holding_user) } {
            set task(this_user_is_assigned_p) 1
        } else {
            set task(this_user_is_assigned_p) 0
        }
    }

    return [array get task]
}

ad_proc -public wf_task_panels {
    -task_id:required
    -action:boolean
    -target
    {-user_id 0}
} {

    Add the panels for a task into the multirow target.  Action
    panels follow non-action panels.  These could be returned by wf_task_info
    in the future with a little rewriting of the workflow pages.

    @param task_id The task in question
    @param action Only return action panels
    @param target The multirow target
    @param user_id Return "show only when task started" panels for this user

    @author Don Baccus (dhogaza@pacifier.com)
} {
    if { $action_p } {
        db_multirow $target action_panels ""
    } else {
        db_multirow $target all_panels ""
    }
}

ad_proc -public wf_journal {
    {-date_format "Mon fmDDfm, YYYY HH24:MI:SS"}
    {-order latest_first}
    case_id
} {

    Get the journal for a case.

    @param date_format Use this to customize the date-format
    used. Must be a valid Oracle date format specification.
    
    @param order Either <code>latest_first</code> or <code>latest_last</code>.

    @return an <code>[array get]</code> form containin two keys:
    <code>case_id</code> and <code>entries</code>.


    The <code>entries</code> key holds a Tcl list of <code>[array
    get]</code> representations with the following keys:
    <code>journal_id, action, action_pretty, creation_date, creation_date_pretty, 
    creation_user, creation_user_name, creation_user_email, creation_ip, msg, attributes</code>.

    The key <code>attributes</code> contains a Tcl list of <code>[array get]</code> representations with
    these keys: <code>name, pretty_name, datatype, wf_datatype, value</code>.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    
    switch -- $order {
        latest_first {
            set sql_order "desc"
        }
        latest_last {
            set sql_order "asc"
        }
        default {
            return -code error "Order must be latest_first or latest_last"
        }
    }

    set entries [list]
    db_foreach journal "
        select j.journal_id,
               j.action,
               j.action_pretty,
               o.creation_date,
               to_char(o.creation_date, :date_format) as creation_date_pretty,
               o.creation_user,
               acs_object.name(o.creation_user) as creation_user_name,
               p.email as creation_user_email, 
               o.creation_ip,
               j.msg
        from   journal_entries j, acs_objects o, parties p
        where  j.object_id = :case_id
          and  o.object_id = j.journal_id
          and  p.party_id (+) =  o.creation_user
        order  by o.creation_date $sql_order
    " -column_array entry {
        
        set entry(attributes) [list]
        
        set journal_id $entry(journal_id)
        db_foreach attributes {
            select a.attribute_name as name, 
                   a.pretty_name,
                   a.datatype, 
                   v.attr_value as value
            from   wf_attribute_value_audit v, acs_attributes a
            where  v.journal_id = :journal_id
            and    a.attribute_id = v.attribute_id
        } -column_array attribute {
            lappend entry(attributes) [array get attribute]
        }
        set entry(attributes_html) [join $entry(attributes) "<br>"]
        
        lappend entries [array get entry]
    }
    
    return [list case_id $case_id entries $entries]
}


ad_proc -public wf_workflow_info {
    workflow_key
} {
    Get the definition of a workflow.
    
    @return an <code>[array get]</code> representation with the following keys: 
    <code>workflow_name, description, start_place, end_place, transitions</code>.
    
    <p>

    The value of <code>transitions</code> is a Tcl list of
    <code>[array get]</code> representations, with these keys:
    <code>transition_key, transition_name, sort_order, attributes</code>.

    <p>

    The <code>attributes</code> is also a Tcl list of <code>[array get]</code> with
    these keys: <code>attribute_name</code>.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    db_1row workflow {
        select t.pretty_name,
               w.description
        from   wf_workflows w, acs_object_types t
        where  w.workflow_key = :workflow_key
        and    t.object_type = w.workflow_key
    } -column_array workflow_info
        
    set workflow_info(transitions) [list]
    
    db_foreach transitions {
        select transition_key, transition_name, sort_order
        from wf_transitions 
        where workflow_key = :workflow_key 
        and trigger_type = 'user'
        order by sort_order asc
    } -column_array transition_info {
        
        set attributes [list]
        set transition_key $transition_info(transition_key)
        db_foreach attributes {
            select a.attribute_name 
            from   wf_transition_attribute_map m, acs_attributes a
            where  m.workflow_key = :workflow_key 
            and    m.transition_key = :transition_key
            and    a.attribute_id = m.attribute_id
        } -column_array attribute_info {
            lappend attributes [array get attribute_info]
        }
        
        set transition_info(attributes) $attributes
        lappend workflow_info(transitions) [array get transition_info]

    }

    # get places ...

    return [array get workflow_info]
}


ad_proc -public wf_task_action {
    -user_id
    {-msg ""}
    -attributes
    -assignments
    task_id
    action
} {
    Tells the workflow engine that the given action has been taken.
    The workflow state will be updated accordingly.
    
    @param action one of 'start', 'cancel', 'finish' or
    'comment'. Comment doesn't change the state of the workflow, but
    can be used to log a message.

    @param msg an optional message to add to the journal.

    @param attributes an [array get] representation of workflow
    attribute values to set.  

    @param assignments an [array get] representation of role assignments
    made by this task for this case.

    @return journal_id of the newly created journal entry.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    if { ![info exists user_id] } {
        set user_id [ad_get_user_id]
    }

    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        
        set journal_id [db_exec_plsql begin_task_action {
            begin
                :1 := workflow_case.begin_task_action(
                    task_id => :task_id, 
                    action => :action, 
                    action_ip => :modifying_ip,
                    user_id => :user_id, 
                    msg => :msg);
            end;
        }]
    
        if { [info exists attributes] } {
            array set attr $attributes
            foreach attribute_name [array names attr] {
                db_exec_plsql set_attribute_value {
                    begin
                        workflow_case.set_attribute_value(
                            journal_id => :journal_id, 
                            attribute_name => :attribute_name, 
                            value => :value
                        );
                    end;
                } -bind [list journal_id $journal_id \
                    attribute_name $attribute_name \
                    value $attr($attribute_name) ]
            }
        }

        if { [info exists assignments] } {
            array set asgn $assignments
            
            set case_id [db_string case_id_from_task { select case_id from wf_tasks where task_id = :task_id}]

            foreach role_key [array names asgn] {
                db_exec_plsql clear_assignments { 
                    begin 
                        workflow_case.clear_manual_assignments(
                            case_id => :case_id,
                            role_key => :role_key
                        );
                    end;
                }
                
                foreach party_id $asgn($role_key) {
                    db_exec_plsql add_manual_assignment {
                        begin
                            workflow_case.add_manual_assignment(
                                case_id => :case_id,
                                role_key => :role_key,
                                party_id => :party_id
                            );
                        end;
                    }
                }
            }
        }

        db_exec_plsql end_task_action {
            begin
                workflow_case.end_task_action(
                    journal_id => :journal_id,
                    action => :action,
                    task_id => :task_id
                );
            end;
        }
    } 
    
    return $journal_id
}




ad_proc -public wf_message_transition_fire {
    task_id
} {
    Fires a message transition.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    db_exec_plsql transition_fire {
        begin
            workflow_case.fire_message_transition(
                task_id => :task_id
            );
        end;
    }
}


#####
#
# WORKFLOW CASE API
#
#####

ad_proc -public wf_case_new {
    -case_id
    workflow_key
    context_key
    object_id
} {
    Creates and initializes a case of the given workflow type.

    @param case_id for double-click protection, you can optionally supply a 
    case_id to use here.

    @return the case_id of the new case. Throws an error in case of any problems.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    set user_id [ad_get_user_id]
    set creation_ip [ad_conn peeraddr]


    if { ![info exists case_id] } {
        set case_id ""
    }
    
    set case_id [db_exec_plsql workflow_case_new ""]

    db_exec_plsql workflow_case_start_case ""

    return $case_id
}


ad_proc -public wf_case_suspend {
    {-msg ""}
    case_id
} {
    Suspends a case

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    set user_id [ad_get_user_id]
    set ip_address [ad_conn peeraddr]

    db_exec_plsql case_suspend {
        begin
            workflow_case.suspend(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    }
}


ad_proc -public wf_case_resume {
    {-msg ""}
    case_id
} {
    Resumes a suspended case

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    set user_id [ad_get_user_id]
    set ip_address [ad_conn peeraddr]

    db_exec_plsql case_resume {
        begin
            workflow_case.resume(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    }
}


ad_proc -public wf_case_cancel {
    {-msg ""}
    case_id
} {
    Cancels a case

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} { 
    set user_id [ad_get_user_id]
    set ip_address [ad_conn peeraddr]

    db_exec_plsql case_cancel {
        begin
            workflow_case.cancel(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    }
}


ad_proc -public wf_case_comment {
    case_id
    msg
} {
    Comment on a case

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    set user_id [ad_get_user_id]
    set ip_address [ad_conn peeraddr]
    
    set journal_id [db_exec_plsql case_comment {
        begin
            :1 := journal_entry.new(
                object_id => :case_id,
                action => 'comment',
                creation_user => :user_id,
                creation_ip => :ip_address,
                msg => :msg
            );
        end;
    }]
}

ad_proc -public wf_case_add_manual_assignment {
    -case_id:required
    -role_key:required
    -party_id:required
} {
    db_exec_plsql add_manual_assignment {
	begin
            workflow_case.add_manual_assignment(
                case_id  => :case_id,
                role_key => :role_key,
                party_id => :party_id
            );
        end;
    }
}

ad_proc -public wf_case_remove_manual_assignment {
    -case_id:required
    -role_key:required
    -party_id:required
} {
    db_exec_plsql remove_manual_assignment {
	begin
            workflow_case.remove_manual_assignment(
                case_id  => :case_id,
                role_key => :role_key,
                party_id => :party_id
            );
        end;
    }
}

ad_proc -public wf_case_clear_manual_assignments {
    -case_id:required
    -role_key:required
} {
    db_exec_plsql clear_manual_assignments {
	begin
            workflow_case.clear_manual_assignments(
                case_id  => :case_id,
                role_key => :role_key
            );
        end;
    }
}

ad_proc -public wf_case_set_manual_assignments {
    -case_id:required
    -role_key:required
    -party_id_list:required
} {
    db_transaction {
	wf_case_clear_manual_assignments -case_id $case_id -role_key $role_key
	foreach party_id $party_id_list {
	    wf_case_add_manual_assignment -case_id $case_id -role_key $role_key -party_id $party_id
	}
    }
}	


ad_proc -public wf_case_add_task_assignment {
    -task_id:required
    -party_id:required
    -permanent:boolean
} {
    set permanent_value [ad_decode $permanent_p 1 "t" 0 "f"]
    db_exec_plsql add_task_assignment {
	begin
            workflow_case.add_task_assignment(
                task_id  => :task_id,
                party_id => :party_id,
                permanent_p => :permanent_value
            );
        end;
    }
}

ad_proc -public wf_case_remove_task_assignment {
    -task_id:required
    -party_id:required
    -permanent:boolean
} {
    set permanent_value [ad_decode $permanent_p 1 "t" 0 "f"]
    db_exec_plsql remove_task_assignment {
	begin
            workflow_case.remove_task_assignment(
                task_id  => :task_id,
                party_id => :party_id,
                permanent_p => :permanent_value
            );
        end;
    }
}

ad_proc -public wf_case_clear_task_assignments {
    -task_id:required
    -permanent:boolean
} {
    set permanent_value [ad_decode $permanent_p 1 "t" 0 "f"]
    db_exec_plsql clear_task_assignments {
	begin
            workflow_case.clear_task_assignments(
                task_id  => :task_id,
                permanent_p => :permanent_value
            );
        end;
    }
}

ad_proc -public wf_case_set_task_assignments {
    -task_id:required
    -party_id_list:required
    -permanent:boolean
} {
    db_transaction {
	wf_case_clear_task_assignments -task_id $task_id -permanent=$permanent_p
	foreach party_id $party_id_list {
	    wf_case_add_task_assignment -task_id $task_id -party_id $party_id -permanent=$permanent_p
	}
    }
}	
  

ad_proc -public wf_case_set_case_deadline {
    -case_id:required
    -transition_key:required
    -deadline:required
} {
    db_exec_plsql set_case_deadline {
	begin
            workflow_case.set_case_deadline(
	        case_id => :case_id,
                transition_key => :transition_key,
                deadline => :deadline
            );
        end;
    }
}

ad_proc -public wf_case_remove_case_deadline {
    -case_id:required
    -transition_key:required
} {
    db_exec_plsql remove_case_deadline {
	begin
            workflow_case.remove_case_deadline(
	        case_id => :case_id,
                transition_key => :transition_key
            );
        end;
    }
}




#####
#
# WORKFLOW API
#
#####

ad_proc -public wf_add_place {
    -workflow_key:required
    -place_key
    -place_name:required
    {-sort_order ""}
} {
    if { ![info exists place_key] } {
	set place_key [wf_make_unique -maxlen 100 \
		-taken_names [db_list place_keys {select place_key from wf_places where workflow_key = :workflow_key}] \
		[wf_name_to_key $place_name]]
    }

    db_exec_plsql wf_add_place {
        begin
            workflow.add_place(
                workflow_key => :workflow_key,
                place_key => :place_key,
                place_name => :place_name,
                sort_order => :sort_order
            );
        end;
    }
    wf_workflow_changed $workflow_key
    return $place_key
}

ad_proc -public wf_delete_place {
    -workflow_key:required
    -place_key:required
} {
    db_exec_plsql wf_delete_place {
        begin
            workflow.delete_place(
                workflow_key => :workflow_key,
                place_key => :place_key
            );
        end;
    }
    wf_workflow_changed $workflow_key
}

ad_proc -public wf_add_role {
    -workflow_key:required
    -role_key
    -role_name:required
    {-sort_order ""}
} {
    if { ![info exists role_key] } {
	set role_key [wf_make_unique -maxlen 100 \
		-taken_names [db_list role_keys {select role_key from wf_roles where workflow_key = :workflow_key}] \
		[wf_name_to_key $role_name]]
    }

    db_exec_plsql wf_add_role {
	begin
            workflow.add_role(
                workflow_key => :workflow_key,
                role_key => :role_key,
                role_name => :role_name,
                sort_order => :sort_order
            );
        end;
    }
    wf_workflow_changed $workflow_key
    return $role_key
}

ad_proc -public wf_move_role_up {
    -workflow_key:required
    -role_key:required
} {
    db_exec_plsql move_role_up {
	begin
            workflow.move_role_up(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    }
}

ad_proc -public wf_move_role_down {
    -workflow_key:required
    -role_key:required
} {
    db_exec_plsql move_role_down {
	begin
            workflow.move_role_down(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    }
}

ad_proc -public wf_delete_role {
    -workflow_key:required
    -role_key:required
} {
    db_exec_plsql wf_delete_role {
	begin
            workflow.delete_role(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    }
    wf_workflow_changed $workflow_key
}


ad_proc -public wf_add_transition {
    -workflow_key:required
    -transition_key
    -transition_name:required
    {-role_key ""}
    {-sort_order ""}
    {-trigger_type "user"}
    {-instructions ""}
    {-estimated_minutes ""}
    {-context_key "default"}
} {
    if { ![info exists transition_key] } {
	set transition_key [wf_make_unique -maxlen 100 \
		-taken_names [db_list transition_keys {select transition_key from wf_transitions where workflow_key = :workflow_key}] \
		[wf_name_to_key $transition_name]]
    }

    db_transaction {

	db_exec_plsql wf_add_transition {
	    begin
		workflow.add_transition(
		    workflow_key => :workflow_key,
		    transition_key => :transition_key,
		    transition_name => :transition_name,
		    role_key => :role_key,
		    sort_order => :sort_order,
		    trigger_type => :trigger_type
		);
	    end;
	}
	
	if { ![empty_string_p $estimated_minutes] || ![empty_string_p $instructions] } {
	    db_dml estimated_minutes_and_instructions {
		insert into wf_context_transition_info 
		(context_key, workflow_key, transition_key, estimated_minutes, instructions)
		values (:context_key, :workflow_key, :transition_key, :estimated_minutes, :instructions)
	    }
	}
    }

    wf_workflow_changed $workflow_key
    return $transition_key
}

ad_proc -public wf_delete_transition {
    -workflow_key:required
    -transition_key:required
} {
    db_exec_plsql wf_delete_transition {
	begin
            workflow.delete_transition(
                workflow_key => :workflow_key,
                transition_key => :transition_key
            );
        end;
    }
    wf_workflow_changed $workflow_key
}




ad_proc -public wf_add_arc {
    -workflow_key:required
    -transition_key:required
    -place_key:required
    -direction:required
    {-guard_callback ""}
    {-guard_custom_arg ""}
    {-guard_description ""}
} {
    db_exec_plsql wf_add_arc {
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
	        transition_key => :transition_key,
                place_key => :place_key,
                direction => :direction,
                guard_callback => :guard_callback,
                guard_custom_arg => :guard_custom_arg,
                guard_description => :guard_description
            );
        end;
    }
    wf_workflow_changed $workflow_key
}

ad_proc -public wf_add_arc_out {
    -workflow_key:required
    -from_transition_key:required
    -to_place_key:required
    {-guard_callback ""}
    {-guard_custom_arg ""}
    {-guard_description ""}
} {
    db_exec_plsql wf_add_arc {
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
	        from_transition_key => :from_transition_key,
                to_place_key => :to_place_key,
                guard_callback => :guard_callback,
                guard_custom_arg => :guard_custom_arg,
                guard_description => :guard_description
            );
        end;
    }
    wf_workflow_changed $workflow_key
}

ad_proc -public wf_add_arc_in {
    -workflow_key:required
    -from_place_key:required
    -to_transition_key:required
} {
    db_exec_plsql wf_add_arc {
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
                from_place_key => :from_place_key,
	        to_transition_key => :to_transition_key
            );
        end;
    }
    wf_workflow_changed $workflow_key
}

ad_proc -public wf_delete_arc {
    -workflow_key:required
    -transition_key:required
    -place_key:required
    -direction:required
} {
    db_exec_plsql wf_delete_arc {
        begin
            workflow.delete_arc(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                place_key => :place_key,
                direction => :direction
            );
        end;
    }
    wf_workflow_changed $workflow_key
}

ad_proc -public wf_add_trans_attribute_map {
    -workflow_key:required
    -transition_key:required
    -attribute_id
    -attribute_name
    {-sort_order ""}
} {
    if { ![info exists attribute_id] && ![info exists attribute_name] } {
	return -code error "Either attribute_id or attribute_name must be supplied"
    }
    
    if { [info exists attribute_id] } {
	db_exec_plsql add_trans_attribute_map_attribute_id {
	    begin
	        workflow.add_trans_attribute_map(
                    workflow_key => :workflow_key,
	            transition_key => :transition_key,
	            attribute_id => :attribute_id,
	            sort_order => :sort_order
                );
	    end;
	}
    } else {
	db_exec_plsql add_trans_attribute_map_attribute_name {
	    begin
	        workflow.add_trans_attribute_map(
                    workflow_key => :workflow_key,
	            transition_key => :transition_key,
	            attribute_name => :attribute_name,
	            sort_order => :sort_order
                );
	    end;
	}
    }
}

ad_proc -public wf_delete_trans_attribute_map {
    -workflow_key:required
    -transition_key:required
    -attribute_id:required
} {
    db_exec_plsql delete_trans_attribute_map {
        begin
            workflow.delete_trans_attribute_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                attribute_id => :attribute_id
            );
        end;
    }
}

ad_proc -public wf_add_trans_role_assign_map {
    -workflow_key:required
    -transition_key:required
    -assign_role_key:required
} {
    db_exec_plsql add_trans_role_assign_map {
        begin
            workflow.add_trans_role_assign_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                assign_role_key => :assign_role_key
            );
        end;
    }
}
    
ad_proc -public wf_delete_trans_role_assign_map {
    -workflow_key:required
    -transition_key:required
    -assign_role_key:required
} {
    db_exec_plsql delete_trans_role_assign_map {
        begin
            workflow.delete_trans_role_assign_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                assign_role_key => :assign_role_key
            );
        end;
    }
}


ad_proc -public wf_task_state_pretty {
    task_state
} {
    Returns a pretty-print version of a task state.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    array set pretty {
        enabled Waiting
        started Active
        canceled Canceled
        finished Finished
        overridden Overriden
    }
    return $pretty($task_state)
}


ad_proc -public wf_task_actions {
    task_state
} {
    Returns a list of the possible actions given the task state.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    switch -- $task_state {
        enabled {
            return [list start]
        }
        started {
            return [list finish cancel]
        }
        default {
            return [list]
        }
    }
}

ad_proc -public wf_action_pretty {
    action
} {
    Returns the pretty version of a task action.

    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    array set pretty {
        start Start
        finish Finish
        cancel Cancel
        comment Comment
    }
    return $pretty($action)
}


ad_proc -public wf_simple_workflow_p {
    workflow_key
} {
    Returns whether the workflow is "almost linear" or not.  Roughly,
    "almost linear" means whether we can represent it graphically within
    the confines of HTML.  Currently that means only simple iteration is
    permitted.

    @author Kevin Scaldeferri (kevin@theory.caltech.edu)
    @creation-date 10 July, 2000
} {
    return [ad_decode [db_exec_plsql simple_workflow "begin :1 := workflow.simple_p(:workflow_key); end;"] t 1 f 0 0]
}



#####
#
# EXPORT
#
#####

ad_proc wf_export_workflow {
    {-context_key "default"}
    -new_workflow_key
    -new_table_name
    -new_workflow_pretty_name
    -new_workflow_pretty_plural
    workflow_key
} {
    Generates a SQL script that can re-create this process in another installation.
} {

    if { ![info exists new_workflow_key] } {
        set new_workflow_key $workflow_key
    }

    #####
    #
    # Workflow Object Type
    #
    #####
    
    db_1row workflow_info {
        select wf.description,
        ot.pretty_name,
        ot.pretty_plural,
        ot.table_name
        from   wf_workflows wf,
        acs_object_types ot
        where  wf.workflow_key = :workflow_key
        and    ot.object_type = wf.workflow_key
    }

    if { ![info exists new_table_name] } {
        set new_table_name $table_name
    }
    
    if { ![info exists new_workflow_pretty_name] } {
        set new_workflow_pretty_name $pretty_name
    }

    if { ![info exists new_workflow_pretty_plural] } {
        set new_workflow_pretty_plural $pretty_plural
    }



    append sql "
/*
 * Business Process Definition: $pretty_name ($new_workflow_key[ad_decode $workflow_key $new_workflow_key "" ", copy of $workflow_key"])
 *
 * Auto-generated by ACS Workflow Export, version 4.3
 *
 * Context: $context_key
 */


/*
 * Cases table
 */
create table $new_table_name (
  case_id               integer primary key
                        references wf_cases on delete cascade
);

/* 
 * Declare the object type
 */
[db_map declare_object_type]

"

    #####
    #
    # Places
    #
    #####

    append sql "
/*****
 * Places
 *****/
"

    db_foreach places {
        select place_key,
               place_name,
               sort_order
        from   wf_places
        where  workflow_key = :workflow_key
        order by sort_order asc
    } {
        append sql "[db_map add_place]"
    }

    #####
    #
    # Roles
    #
    #####

    append sql "
/*****
 * Roles
 *****/

"

    db_foreach roles {
        select role_key,
               role_name,
               sort_order
	from   wf_roles
	where  workflow_key = :workflow_key
    } {
	append sql "[db_map add_role]"
    }


    #####
    #
    # Transitions
    #
    #####
    
    append sql "

/*****
 * Transitions
 *****/

"

    db_foreach transitions {
        select transition_key,
               transition_name,
               role_key,
               sort_order,
               trigger_type
        from   wf_transitions
        where  workflow_key = :workflow_key
        order by sort_order asc
    } {
        append sql "[db_map add_transition]"
    }



    #####
    #
    # Arcs
    #
    #####
    
    
    append sql "

/*****
 * Arcs
 *****/

"

    db_foreach arcs {
        select transition_key,
               place_key,
               direction,
               guard_callback,
               guard_custom_arg,
               guard_description
        from   wf_arcs
        where  workflow_key = :workflow_key
        order by transition_key asc
    } {
        append sql "[db_map add_arc]"
    }
    
    
    #####
    #
    # Attributes
    #
    #####
    
    append sql "

/*****
 * Attributes
 *****/

"

    db_foreach attributes {
        select attribute_id,
               attribute_name,
               datatype, 
               pretty_name,
               default_value
        from   acs_attributes
        where  object_type = :workflow_key
    } {
        append sql [db_map create_attribute]

        db_foreach transition_attribute_map {
            select transition_key,
                   sort_order
            from   wf_transition_attribute_map
            where  workflow_key = :workflow_key
            and    attribute_id = :attribute_id
        } {
            append sql [db_map add_trans_attribute_map]
        }
    
    }



    #####
    # 
    # Transition-role-assignment map
    #
    #####
    
    append sql "
/*****
 * Transition-role-assignment-map
 *****/

"

    db_foreach transition_role_assign_map {
        select transition_key,
               assign_role_key
          from wf_transition_role_assign_map
         where workflow_key = :workflow_key
         order by transition_key
    } {
        append sql [db_map add_trans_role_assign_map]
    }
    
    
    #####
    #
    # Context-Transition info
    #
    #####
    
    append sql "

/*
 * Context/Transition info
 * (for context = $context_key)
 */

"

    db_foreach context_transition_info {
        select transition_key,
               estimated_minutes,
               instructions,
               enable_callback,
               enable_custom_arg,
               fire_callback,
               fire_custom_arg,
               time_callback,
               time_custom_arg,
               deadline_callback,
               deadline_custom_arg,
               deadline_attribute_name,
               hold_timeout_callback,
               hold_timeout_custom_arg,
               notification_callback,
               notification_custom_arg,
               unassigned_callback,
               unassigned_custom_arg
        from   wf_context_transition_info
        where  workflow_key = :workflow_key
        and    context_key = :context_key
    } {
        append sql "insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('[db_quote $context_key]',
 '[db_quote $new_workflow_key]',
 '[db_quote $transition_key]',
 [ad_decode $estimated_minutes "" "null" $estimated_minutes],
 '[db_quote $instructions]',
 '[db_quote $enable_callback]',
 '[db_quote $enable_custom_arg]',
 '[db_quote $fire_callback]',
 '[db_quote $fire_custom_arg]',
 '[db_quote $time_callback]',
 '[db_quote $time_custom_arg]',
 '[db_quote $deadline_callback]',
 '[db_quote $deadline_custom_arg]',
 '[db_quote $deadline_attribute_name]',
 '[db_quote $hold_timeout_callback]',
 '[db_quote $hold_timeout_custom_arg]',
 '[db_quote $notification_callback]',
 '[db_quote $notification_custom_arg]',
 '[db_quote $unassigned_callback]',
 '[db_quote $unassigned_custom_arg]');

"
    }
    
    
    #####
    #
    # Context-Role info
    #
    #####
    
    append sql "

/*
 * Context/Role info
 * (for context = $context_key)
 */

"

    db_foreach context_role_info {
	select role_key,
	       assignment_callback,
	       assignment_custom_arg
	from   wf_context_role_info
	where  workflow_key = :workflow_key
	and    context_key = :context_key
    } {
	append sql "insert into wf_context_role_info
(context_key,
 workflow_key,
 role_key,
 assignment_callback,
 assignment_custom_arg)
values
('[db_quote $context_key]',
 '[db_quote $new_workflow_key]',
 '[db_quote $role_key]',
 '[db_quote $assignment_callback]',
 '[db_quote $assignment_custom_arg]');

"
    }


    #####
    #
    # Context Task Panels
    #
    #####
    
    append sql "

/*
 * Context Task Panels
 * (for context = $context_key)
 */

"

    db_foreach context_task_panels {
        select transition_key,
               sort_order,
               header,
               template_url,
               overrides_action_p,
	       overrides_both_panels_p,
               only_display_when_started_p
        from   wf_context_task_panels
        where  context_key = :context_key
        and    workflow_key = :workflow_key
        order by transition_key asc, sort_order asc
    } {
        append sql "insert into wf_context_task_panels 
(context_key,
 workflow_key,
 transition_key,
 sort_order,
 header,
 template_url,
 overrides_action_p,
 overrides_both_panels_p,
 only_display_when_started_p)
values
('[db_quote $context_key]',
 '[db_quote $new_workflow_key]',
 '[db_quote $transition_key]',
 [ad_decode $sort_order "" "null" $sort_order],
 '[db_quote $header]',
 '[db_quote $template_url]',
 '[db_quote $overrides_action_p]',
 '[db_quote $overrides_both_panels_p]',
 '[db_quote $only_display_when_started_p]');

"
    }

    append sql "
commit;
"

    return $sql
}

ad_proc wf_split_query_url_to_arg_spec { query_url } {
    Splits a URL including query arguments (e.g., /foo/bar?baz=greble&yank=zazz)
    up into a list of lists of name/value pairs, that can be passed as an argument
    to export_vars.
    <p>
    Useful for pages that receive a return_url argument, but wants to
    execute the actual return using a form submit button.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date Feb 26, 2001
} {
    set arg_spec {}
    foreach arg [split [lindex [split $query_url "?"] 1] "&"] {
	set argv [split $arg "="]
	set name [ns_urldecode [lindex $argv 0]]
	set value [ns_urldecode [lindex $argv 1]]
	lappend arg_spec [list $name $value]
    }
    return $arg_spec
}

ad_proc wf_sweep_time_events {} {
    Sweep timed transitions and hold timeouts.  This was originally done with Oracle
    but has been pulled out here so it will work with any RDBMS.

    @author Don Baccus (dhogaza@pacifier.com)
} {

    ns_log Notice "workflow-case: sweeping timed transitions"
    db_exec_plsql sweep_timed_transitions ""

    ns_log Notice "workflow-case: sweeping hold timeout"
    db_exec_plsql sweep_hold_timeout ""
}




ad_proc wf_sweep_message_transition_tcl {} {

    Sweep those message transitions that have a TCL callback
    and advance the transitions.
    The procedure is designed to allow WF transitions to 
    trigger TCL procedures, which is usually impossible,
    because the entire WF works on the PlPg/SQL level.

    We dont want to make changes in the WF data model right
    now, so we're looking at the "enabled" callbacls of message 
    transitions and check if the actual PlPg/SQL call is empty,
    but if there is an argument and execute this argument as
    a TCL call. Ugly, but may work...

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    ns_log Notice "workflow-case: sweeping message transition TCL"
    set user_id [ad_get_user_id]
    set ip_address [ad_conn peeraddr]

    set sweep_sql "
	select
		ta.*,
		tr.*,
		ca.object_id,
		ti.enable_custom_arg as tcl_call
	from
		wf_tasks ta,
		wf_cases ca,
		wf_transitions tr,
		wf_context_transition_info ti
	where
		ta.workflow_key = tr.workflow_key
		and ta.transition_key = tr.transition_key
		and ta.workflow_key = ti.workflow_key
		and ta.transition_key = ti.transition_key
		and ta.case_id = ca.case_id
		and
			(ti.enable_callback = '' OR ti.enable_callback is NULL) and
			ta.state = 'enabled'
			and tr.trigger_type = 'message'
    "

    # Add an entry to the journal
    set journal_sql "
		select journal_entry__new (
			null,
			:case_id,
		        'task ' || :task_id || ' tcl enable',
		        'Enable TCL task' || :task_id || ': ' || :tcl_call,
			now(),
			:user_id,
			:ip_address,
			:error_msg
		)
    "


    set found_transition_p 1
    while {$found_transition_p} {

	# By default: Just do this once...
	set found_transition_p 0

	# Execute the TCL commands and initiate events.
	db_foreach sweep_message_transition_tcl $sweep_sql {

	    # Found a transition to sweep - loop again
	    set found_transition_p 1

	    set error_msg "successful"
	    ns_log Notice "wf_sweep_message_transition_tcl: executing '$tcl_call' ..."
	    if {[catch {
		eval $tcl_call
		ns_log Notice "wf_sweep_message_transition_tcl: ... successful"
		# Advance the message transition
		wf_message_transition_fire $task_id
	    } errmsg]} {
		ns_log Notice "wf_sweep_message_transition_tcl: ... error: $errmsg"
		set error_msg $errmsg
	    }
	    db_exec_plsql journal_entry $journal_sql
	}

    }

}


