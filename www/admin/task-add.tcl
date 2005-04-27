ad_page_contract {
    Add task
} {
    workflow_key:notnull
    return_url:optional
} -properties {
    context
    export_vars
    trigger_types:multirow
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}


set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow_name"] [list "define?[export_url_vars workflow_key]" "Edit process"] "Add task"]

set export_vars [export_vars -form {workflow_key return_url}]

template::multirow create trigger_types value text selected_string 
foreach option { 
    { user User } 
    { automatic Automatic }
    { message Message } 
    { time Time } 
} {
    template::multirow append trigger_types [lindex $option 0] [lindex $option 1] ""
}

template::multirow create roles role_key role_name
db_multirow roles roles {
    select r.role_key, 
           r.role_name 
      from wf_roles r
     where r.workflow_key = :workflow_key
     order by r.sort_order
}
template::multirow append roles "" "-- None --"
template::multirow append roles "<new>" "-- Create new role --"

ad_return_template
