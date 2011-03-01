ad_page_contract {
    Add place.
} {
    workflow_key:notnull
} -properties {
    context
    export_vars
    special_widget
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_url_vars workflow_key]" "Edit process"] "Add place"]

set export_vars [export_form_vars workflow_key]

set num_start [db_string num_start_places { 
    select decode(count(*),0,0,1) from wf_places 
    where  workflow_key = :workflow_key
    and    place_key = 'start'
}]

set num_end [db_string num_start_places { 
    select decode(count(*),0,0,1) from wf_places 
    where  workflow_key = :workflow_key
    and    place_key = 'end'
}]

set special_widget {}
if { $num_start == 0 || $num_end == 0 } {
    set special_widget "<select name=special>
    <option value=\"\" selected>--Normal place--</option>
    "

    if { $num_start == 0 } {
	append special_widget "<option value=\"start\">Start place</option>"
    }
    if { $num_end == 0 } {
	append special_widget "<option value=\"end\">End place</option>"
    }
    append special_widget "</select>"
}

ad_return_template
