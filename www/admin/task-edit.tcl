ad_page_contract {
    Edit task.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date September 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    return_url:optional
    {context_key "default"}
    {new_role_p:boolean 0}
} -properties {
    transition_name
    context
    export_vars
    trigger_types:multirow
    roles:multirow
    estimated_minutes
    instructions
    new_role_p
    focus
}

db_1row workflow_info {
    select pretty_name as workflow_name
      from acs_object_types
     where object_type = :workflow_key
}

set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow_name"]  "Edit task"]
set export_vars [export_vars -form {workflow_key transition_key return_url context_key}]

db_1row transition_info {
    select transition_name,
           trigger_type,
           role_key as selected_role_key
    from   wf_transitions
    where  transition_key = :transition_key
    and    workflow_key = :workflow_key
}

template::multirow create trigger_types value text selected_string
foreach option { 
    { user User } 
    { automatic Automatic } 
    { message Message } 
    { time Time } 
} {
    template::multirow append trigger_types [lindex $option 0] [lindex $option 1] [ad_decode $trigger_type [lindex $option 0] "SELECTED" ""]
}

template::multirow create roles role_key role_name selected_string
db_multirow roles roles {
    select r.role_key, 
           r.role_name,
           decode(role_key, :selected_role_key, 'SELECTED', '') as selected_string 
      from wf_roles r
     where r.workflow_key = :workflow_key
     order by r.sort_order
}

template::multirow append roles "" "-- None --" [ad_decode $selected_role_key "" "SELECTED" ""]
template::multirow append roles "<new>" "-- Create new role --" ""

set estimated_minutes {}
set instructions {}

db_0or1row transition_context_info {
    select estimated_minutes, instructions 
      from wf_context_transition_info 
     where workflow_key = :workflow_key 
       and transition_key = :transition_key 
       and context_key = :context_key
}

set focus "task.transition_name"
if { $new_role_p } {
    set focus "task.role_name"
}

ad_return_template

