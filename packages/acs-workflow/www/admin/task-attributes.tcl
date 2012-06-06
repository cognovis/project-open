ad_page_contract {
    Manage attributes to set during a task.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    transition_key
    workflow_key
    transition_name
    context
    attributes:multirow
    add_url
    add_export_vars
}

db_1row workflow_and_transition_name {
    select ot.pretty_name as workflow_name,
           t.transition_name
    from   acs_object_types ot,
           wf_transitions t
    where  ot.object_type = :workflow_key
    and    t.workflow_key = ot.object_type
    and    t.transition_key = :transition_key
}

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] [list "define?[export_vars -url {workflow_key transition_key}]" "Edit process"] "Attributes for $transition_name"]

set counter 0
db_multirow attributes attributes {
    select ta.sort_order,
           a.attribute_id,
           a.attribute_name,
           a.pretty_name,
           a.datatype,
           '' as delete_url,
           '' as move_up_url
    from   wf_transition_attribute_map ta,
           acs_attributes a
    where  ta.workflow_key = :workflow_key
    and    ta.transition_key = :transition_key
    and    a.attribute_id = ta.attribute_id
    order by sort_order
} {
    incr counter
    set vars { 
	workflow_key 
	transition_key  
	attribute_id
	{
	    return_url 
	    "task-attributes?[export_vars -url {workflow_key transition_key return_url}]"
	}
    }
    set delete_url "task-attribute-delete?[export_vars -url $vars]"
    if { $counter > 1 } { 
	set move_up_url "task-attribute-move-up?[export_vars -url $vars]"
    }
}


db_multirow attributes_not_set attributes_not_set {
    select a.attribute_id,
           a.sort_order,
           a.attribute_name,
           a.pretty_name,
           a.datatype
    from   acs_attributes a
    where  a.object_type = :workflow_key
    and not exists (select 1 from wf_transition_attribute_map m
                    where  m.workflow_key = :workflow_key
                    and    m.transition_key = :transition_key
                    and    m.attribute_id = a.attribute_id)
    order by sort_order
}

set add_url "task-attribute-add"
set vars { 
    workflow_key 
    transition_key  
    {
	return_url 
	"task-attributes?[export_vars -url {workflow_key transition_key return_url}]"
    }
}
set add_export_vars [export_vars -form $vars]

ad_return_template


