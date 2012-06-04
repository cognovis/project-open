ad_page_contract {
    Displays information about a case.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 18 August 2000
    @cvs-id $Id$
} {
    case_id:integer,notnull
} -properties {
    context
    case:onerow
    tasks:multirow
    attributes:multirow
    live_tokens:multirow
    dead_tokens:multirow
    enabled_transitions:multirow
}



db_1row case_info {
    select case_id, acs_object.name(object_id) as object_name, state as state from wf_cases where case_id = :case_id
} -column_array case

set context [list "Case $case(object_name)"]

db_multirow tasks tasks {
    select task_id, transition_key, state, case_id
    from   wf_tasks
    where  case_id = :case_id
    order by decode(state, 'started', 1, 'enabled', 2, 'finished', 3, 4)
}


db_multirow attributes attributes {
    select a.attribute_name as name, acs_object.get_attribute(c.case_id, a.attribute_name) as value
    from   acs_attributes a, wf_cases c
    where  a.object_type = c.workflow_key
    and    c.case_id = :case_id
}

db_multirow live_tokens live_tokens {
    select token_id, place_key, case_id, state, locked_task_id
    from   wf_tokens
    where  case_id = :case_id
    and    state in ('free', 'locked')
}


db_multirow dead_tokens dead_tokens {
    select token_id, place_key, case_id, state, locked_task_id,
           to_char(produced_date, 'YYYY-MM-DD HH24:MI:SS') as produced_date_pretty,
           to_char(locked_date, 'YYYY-MM-DD HH24:MI:SS') as locked_date_pretty,
           to_char(consumed_date, 'YYYY-MM-DD HH24:MI:SS') as consumed_date_pretty,
           to_char(canceled_date, 'YYYY-MM-DD HH24:MI:SS') as canceled_date_pretty
    from   wf_tokens
    where  case_id = :case_id
    and    state in ('consumed', 'canceled')
}


db_multirow enabled_transitions enabled_transitions {
    select case_id, transition_key, transition_name, trigger_type
    from   wf_enabled_transitions
    where  case_id = :case_id
}

ad_return_template