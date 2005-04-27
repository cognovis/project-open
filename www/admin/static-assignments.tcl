ad_page_contract {
    Manage static assignments for a workflow.
} {
    workflow_key
    {context_key "default"}
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    workflow_name
    workflow_key
    context
    context_slider:multirow
    context_add_url
    tasks:multirow
}

db_1row workflow_name {
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Static Assignments"]


db_multirow context_slider context_slider {
    select context_key as context_key_from_db,
           context_name as title,
           '' as url,
           0 as selected_p
    from   wf_contexts
    order by context_name
} {
    if { [string equal $context_key $context_key_from_db] } {
        set selected_p 1
    }
    set url "static-assignments?[export_vars -url { workflow_key {context_key $context_key_from_db} }]"
}
set context_add_url "context-add?[export_vars -url {workflow_key {return_url "static-assignments?[export_vars -url {workflow_key context_key}]"}}]"


set last_transition_key {}
db_multirow tasks tasks {
    select tr.transition_key, 
           tr.transition_name,
           p.party_id,
           acs_object.name(p.party_id) as party_name,
           p.email as party_email,
           '' as user_select_widget
    from   wf_transition_info tr,
           wf_context_assignments ca,
           parties p
    where  tr.workflow_key = :workflow_key
    and    tr.context_key = :context_key
    and    tr.trigger_type = 'user'
    and    tr.assignment_callback is null
    and    ca.context_key (+) = tr.context_key
    and    ca.transition_key (+) = tr.transition_key
    and    p.party_id (+) = ca.party_id
    and    not exists 
               (select 1 
                from   wf_transition_assignment_map 
                where  workflow_key = tr.workflow_key
                and    assign_transition_key = tr.transition_key)
    order by tr.sort_order, tr.transition_key
} {
    if { ![string equal $transition_key $last_transition_key] } {
	set counter 0
	set user_select_widget "<select name=party_id><option>--Please select--</option>"
	db_foreach parties {
            select p.party_id as sel_party_id,
                   acs_object.name(p.party_id) as sel_name,
                   p.email as sel_email
            from   parties p
            where  p.party_id not in 
                  (select ca.party_id 
                   from   wf_context_assignments ca
                   where  ca.workflow_key = :workflow_key 
                   and    ca.context_key = :context_key 
                   and    ca.transition_key = :transition_key)
	} {
            incr counter
            append user_select_widget "<option value=\"$sel_party_id\">$sel_name[ad_decode $sel_email "" "" " ($sel_email)"]</option>"
	}   
	append user_select_widget "</select>"
	if { $counter == 0 } {
	    set user_select_widget ""
	}
	set last_user_select_widget $user_select_widget
	set last_transition_key $transition_key
    } else {
	set user_select_widget $last_user_select_widget
    }
}

ad_return_template

